import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/openai_client.dart';
import '../../core/error/error_handler.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/models/translation.dart';
import '../../shared/notifiers/language_prefs_notifier.dart';
import '../../shared/utils/clipboard_utils.dart';

/// States for the text translation flow.
enum TextTranslationState { idle, translating, success, error }

/// ViewModel for the text translation feature.
///
/// Manages text input, translation via GPT-4o, collapsible sections,
/// clipboard detection, and history integration.
class TextViewModel extends ChangeNotifier {
  TextViewModel({
    required OpenAIClient apiClient,
    required HistoryRepository historyRepo,
    required LanguagePrefsNotifier languagePrefs,
  })  : _apiClient = apiClient,
        _historyRepo = historyRepo,
        _languagePrefs = languagePrefs {
    _languagePrefs.addListener(_onLanguageChanged);
  }

  final OpenAIClient _apiClient;
  final HistoryRepository _historyRepo;
  final LanguagePrefsNotifier _languagePrefs;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _playerSubscription;
  bool _isDisposed = false;

  // --- State ---
  TextTranslationState state = TextTranslationState.idle;
  String inputText = '';
  TranslationResponse? result;
  String? detectedLanguage;
  String? errorMessage;
  bool isReversed = false;
  bool contextExpanded = false;
  bool pronunciationExpanded = false;
  bool isFavorite = false;
  int? _lastSavedId;
  List<Translation> recentTranslations = [];
  bool isSpeaking = false;
  String? _currentTtsPath;

  /// Translate the current input text.
  Future<void> translate() async {
    if (inputText.trim().length < 3) {
      errorMessage = 'Too short to translate';
      notifyListeners();
      // Clear error after a moment.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (errorMessage == 'Too short to translate') {
        errorMessage = null;
        notifyListeners();
      }
      return;
    }

    state = TextTranslationState.translating;
    errorMessage = null;
    result = null;
    contextExpanded = false;
    pronunciationExpanded = false;
    isFavorite = false;
    _lastSavedId = null;
    notifyListeners();

    try {
      final sourceLang = isReversed
          ? _languagePrefs.targetLanguage.code
          : _languagePrefs.sourceLanguage.code;
      final targetLang = isReversed
          ? _languagePrefs.sourceLanguage.code
          : _languagePrefs.targetLanguage.code;

      result = await _apiClient.translate(
        text: inputText,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      detectedLanguage = result!.detectedLanguage;
      state = TextTranslationState.success;
      notifyListeners();

      // Auto-save to history.
      await _saveToHistory();

      // Refresh recent translations.
      await loadRecentTranslations();
    } catch (e) {
      state = TextTranslationState.error;
      errorMessage = mapErrorToMessage(e);
      notifyListeners();
    }
  }

  /// Toggle translation direction.
  void toggleDirection() {
    isReversed = !isReversed;
    notifyListeners();
  }

  /// Set input text (from keyboard or clipboard paste).
  void setInputText(String text) {
    inputText = text;
    notifyListeners();
  }

  /// Clear input and result.
  void clear() {
    inputText = '';
    result = null;
    detectedLanguage = null;
    errorMessage = null;
    contextExpanded = false;
    pronunciationExpanded = false;
    isFavorite = false;
    _lastSavedId = null;
    state = TextTranslationState.idle;
    notifyListeners();
  }

  /// Toggle context section expanded state.
  void toggleContext() {
    contextExpanded = !contextExpanded;
    notifyListeners();
  }

  /// Toggle pronunciation section expanded state.
  void togglePronunciation() {
    pronunciationExpanded = !pronunciationExpanded;
    notifyListeners();
  }

  /// Check clipboard for translatable content.
  Future<String?> checkClipboard() async {
    return ClipboardUtils.getTranslatableContent();
  }

  /// Copy text to clipboard.
  void copyText(String text) {
    ClipboardUtils.copy(text);
  }

  /// Toggle favorite on current result.
  Future<void> toggleFavorite() async {
    if (_lastSavedId == null) return;

    isFavorite = !isFavorite;
    notifyListeners();

    await _historyRepo.toggleFavorite(_lastSavedId!, isFavorite);
  }

  /// Load recent text translations for the quick-access list.
  Future<void> loadRecentTranslations() async {
    try {
      recentTranslations = await _historyRepo.getTranslations(
        typeFilter: 'text',
        limit: 3,
      );
      notifyListeners();
    } catch (_) {
      // Silently fail -- recent list is non-critical.
    }
  }

  /// Save the current translation to history.
  Future<void> _saveToHistory() async {
    if (result == null) return;

    final sourceLang = isReversed
        ? _languagePrefs.targetLanguage.code
        : _languagePrefs.sourceLanguage.code;
    final targetLang = isReversed
        ? _languagePrefs.sourceLanguage.code
        : _languagePrefs.targetLanguage.code;

    final translation = Translation(
      type: 'text',
      sourceText: inputText,
      translatedText: result!.translatedText,
      sourceLanguage: detectedLanguage ?? sourceLang,
      targetLanguage: targetLang,
      context: result!.context,
      pronunciation: result!.pronunciation,
      createdAt: DateTime.now(),
    );

    _lastSavedId = await _historyRepo.insertTranslation(translation);
  }

  /// The source language display name for the current direction.
  String get sourceLanguageDisplay {
    if (isReversed) {
      return _languagePrefs.targetLanguage.displayName;
    }
    return _languagePrefs.sourceLanguage.displayName;
  }

  /// The target language display name for the current direction.
  String get targetLanguageDisplay {
    if (isReversed) {
      return _languagePrefs.sourceLanguage.displayName;
    }
    return _languagePrefs.targetLanguage.displayName;
  }

  /// Forward language pref changes to rebuild the direction toggle.
  void _onLanguageChanged() {
    if (!_isDisposed) notifyListeners();
  }

  /// Speak text via OpenAI TTS.
  Future<void> speakText(String text) async {
    try {
      isSpeaking = true;
      notifyListeners();

      if (_currentTtsPath != null) {
        try {
          await File(_currentTtsPath!).delete();
        } catch (_) {}
      }

      _currentTtsPath = await _apiClient.textToSpeech(
        text: text,
        speed: 0.85,
      );

      if (_isDisposed) return;

      _playerSubscription?.cancel();
      _playerSubscription = _player.onPlayerComplete.listen((_) {
        isSpeaking = false;
        if (!_isDisposed) notifyListeners();
      });

      await _player.play(DeviceFileSource(_currentTtsPath!));
    } catch (_) {
      isSpeaking = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _languagePrefs.removeListener(_onLanguageChanged);
    _playerSubscription?.cancel();
    _player.dispose();
    if (_currentTtsPath != null) {
      try {
        File(_currentTtsPath!).delete();
      } catch (_) {}
    }
    super.dispose();
  }
}
