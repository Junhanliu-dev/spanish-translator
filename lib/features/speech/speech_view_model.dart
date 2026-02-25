import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/api/openai_client.dart';
import '../../core/error/error_handler.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/models/speech_state.dart';
import '../../shared/models/translation.dart';
import '../../shared/notifiers/language_prefs_notifier.dart';
import '../../shared/utils/clipboard_utils.dart';

/// ViewModel for the speech translation feature.
///
/// Manages the record-transcribe-translate-TTS pipeline and exposes
/// observable state for the UI.
class SpeechViewModel extends ChangeNotifier {
  SpeechViewModel({
    required OpenAIClient apiClient,
    required HistoryRepository historyRepo,
    required LanguagePrefsNotifier languagePrefs,
  })  : _apiClient = apiClient,
        _historyRepo = historyRepo,
        _languagePrefs = languagePrefs,
        _recorder = AudioRecorder(),
        _player = AudioPlayer();

  final OpenAIClient _apiClient;
  final HistoryRepository _historyRepo;
  final LanguagePrefsNotifier _languagePrefs;
  final AudioRecorder _recorder;
  final AudioPlayer _player;
  StreamSubscription<void>? _playerSubscription;
  bool _isDisposed = false;

  // --- State ---
  SpeechState state = SpeechState.idle;
  String? sourceText;
  String? translatedText;
  String? translationContext;
  String? pronunciation;
  String? detectedLanguage;
  String? errorMessage;
  String? _audioFilePath;
  bool isSwapped = false;
  bool isTTSPlaying = false;
  bool isSaved = false;

  /// Start recording audio.
  ///
  /// Requests microphone permission, starts the audio recorder, and
  /// transitions to [SpeechState.recording].
  Future<void> startRecording() async {
    if (state != SpeechState.idle) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      errorMessage = 'Microphone access is required for speech translation.';
      state = SpeechState.error;
      _safeNotify();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (_isDisposed) return;
      state = SpeechState.idle;
      errorMessage = null;
      _safeNotify();
      return;
    }

    // Reset previous results.
    sourceText = null;
    translatedText = null;
    translationContext = null;
    pronunciation = null;
    detectedLanguage = null;
    errorMessage = null;
    isSaved = false;

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    state = SpeechState.recording;
    notifyListeners();
  }

  /// Stop recording and begin the transcribe-translate-TTS pipeline.
  Future<void> stopRecording() async {
    if (state != SpeechState.recording) return;

    final path = await _recorder.stop();
    if (path == null) {
      state = SpeechState.idle;
      notifyListeners();
      return;
    }

    await _processRecording(path);
  }

  /// Full pipeline after recording stops.
  Future<void> _processRecording(String audioPath) async {
    state = SpeechState.processing;
    notifyListeners();

    try {
      // Step 1: Transcribe audio via Whisper.
      final (text, lang) = await _apiClient.transcribe(
        audioFilePath: audioPath,
      );
      sourceText = text;
      detectedLanguage = lang;
      notifyListeners();

      // Step 2: Translate via GPT-4o.
      final targetLang = isSwapped
          ? _languagePrefs.sourceLanguage.code
          : _languagePrefs.targetLanguage.code;
      final sourceLang = isSwapped
          ? _languagePrefs.targetLanguage.code
          : detectedLanguage!;

      final response = await _apiClient.translate(
        text: text,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        contextHint: 'food ordering at a restaurant',
      );
      translatedText = response.translatedText;
      translationContext = response.context;
      pronunciation = response.pronunciation;
      notifyListeners();

      // Step 3: Clean up previous TTS file and generate new one.
      if (_audioFilePath != null) {
        try {
          await File(_audioFilePath!).delete();
        } catch (_) {}
      }
      _audioFilePath = await _apiClient.textToSpeech(
        text: response.translatedText,
        speed: 0.9,
      );

      state = SpeechState.success;
      _safeNotify();

      // Step 4: Auto-play TTS after a brief delay so the user can read first.
      await Future<void>.delayed(const Duration(seconds: 1));
      if (_isDisposed) return;
      await playTTS();

      // Clean up the recording file.
      try {
        await File(audioPath).delete();
      } catch (_) {
        // Ignore cleanup errors.
      }
    } catch (e) {
      state = SpeechState.error;
      errorMessage = mapErrorToMessage(e);
      _safeNotify();

      // Auto-recover to idle after 1.5 seconds.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (_isDisposed) return;
      state = SpeechState.idle;
      errorMessage = null;
      _safeNotify();
    }
  }

  /// Replay the TTS audio.
  Future<void> playTTS() async {
    if (_audioFilePath == null) return;

    try {
      isTTSPlaying = true;
      _safeNotify();

      _playerSubscription?.cancel();
      _playerSubscription = _player.onPlayerComplete.listen((_) {
        isTTSPlaying = false;
        _safeNotify();
      });

      await _player.play(DeviceFileSource(_audioFilePath!));
    } catch (_) {
      isTTSPlaying = false;
      _safeNotify();
    }
  }

  /// Stop TTS playback.
  Future<void> stopTTS() async {
    await _player.stop();
    isTTSPlaying = false;
    notifyListeners();
  }

  /// Swap source/target languages (conversation mode).
  void swapLanguages() {
    isSwapped = !isSwapped;
    notifyListeners();
  }

  /// Save the current translation to history.
  Future<void> saveToHistory() async {
    if (sourceText == null || translatedText == null) return;
    if (isSaved) return;

    final targetLang = isSwapped
        ? _languagePrefs.sourceLanguage.code
        : _languagePrefs.targetLanguage.code;
    final sourceLang = isSwapped
        ? _languagePrefs.targetLanguage.code
        : (detectedLanguage ?? _languagePrefs.sourceLanguage.code);

    final translation = Translation(
      type: 'speech',
      sourceText: sourceText!,
      translatedText: translatedText!,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      context: translationContext,
      pronunciation: pronunciation,
      createdAt: DateTime.now(),
    );

    await _historyRepo.insertTranslation(translation);
    isSaved = true;
    notifyListeners();
  }

  /// Copy text to clipboard.
  void copyText(String text) {
    ClipboardUtils.copy(text);
  }

  /// The display name for the current source language.
  String get sourceLanguageDisplay {
    if (isSwapped) {
      return _languagePrefs.targetLanguage.displayName;
    }
    if (detectedLanguage != null) {
      return _languageCodeToName(detectedLanguage!);
    }
    return _languagePrefs.sourceLanguage.displayName;
  }

  /// The display name for the current target language.
  String get targetLanguageDisplay {
    if (isSwapped) {
      return _languagePrefs.sourceLanguage.displayName;
    }
    return _languagePrefs.targetLanguage.displayName;
  }

  String _languageCodeToName(String code) {
    return switch (code) {
      'en' => 'English',
      'zh' => 'Mandarin',
      'es' => 'Spanish',
      'eu' => 'Basque',
      _ => code.toUpperCase(),
    };
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playerSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
