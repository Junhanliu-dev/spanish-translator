import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/openai_client.dart';
import '../../core/error/error_handler.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/models/translation.dart';

/// States for the discover/lookup flow.
enum DiscoverState { idle, searching, success, error }

/// ViewModel for the Discover feature.
///
/// Manages artwork/landmark lookup via GPT-4o, TTS playback,
/// and history integration.
class DiscoverViewModel extends ChangeNotifier {
  DiscoverViewModel({
    required OpenAIClient apiClient,
    required HistoryRepository historyRepo,
  })  : _apiClient = apiClient,
        _historyRepo = historyRepo;

  final OpenAIClient _apiClient;
  final HistoryRepository _historyRepo;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _playerSubscription;
  bool _isDisposed = false;

  // --- State ---
  DiscoverState state = DiscoverState.idle;
  String query = '';
  LandmarkDescription? result;
  String? errorMessage;
  bool isSpeaking = false;
  bool isFavorite = false;
  int? _lastSavedId;
  String? _currentTtsPath;

  /// Set query text from input field.
  void setQuery(String text) {
    query = text;
    notifyListeners();
  }

  /// Look up the artwork/landmark.
  Future<void> search() async {
    if (query.trim().length < 2) {
      errorMessage = 'Please enter at least 2 characters';
      notifyListeners();
      await Future<void>.delayed(const Duration(seconds: 2));
      if (errorMessage == 'Please enter at least 2 characters') {
        errorMessage = null;
        notifyListeners();
      }
      return;
    }

    state = DiscoverState.searching;
    errorMessage = null;
    result = null;
    isFavorite = false;
    _lastSavedId = null;
    notifyListeners();

    try {
      result = await _apiClient.describeLandmark(name: query.trim());
      state = DiscoverState.success;
      notifyListeners();

      // Auto-save to history.
      await _saveToHistory();
    } catch (e) {
      state = DiscoverState.error;
      errorMessage = mapErrorToMessage(e);
      notifyListeners();
    }
  }

  /// Speak the description via OpenAI TTS.
  Future<void> speakDescription() async {
    if (result == null) return;

    try {
      isSpeaking = true;
      notifyListeners();

      if (_currentTtsPath != null) {
        try {
          await File(_currentTtsPath!).delete();
        } catch (_) {}
      }

      _currentTtsPath = await _apiClient.textToSpeech(
        text: result!.description,
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

  /// Clear input and result.
  void clear() {
    query = '';
    result = null;
    errorMessage = null;
    isFavorite = false;
    _lastSavedId = null;
    state = DiscoverState.idle;
    notifyListeners();
  }

  /// Toggle favorite on the saved history entry.
  Future<void> toggleFavorite() async {
    if (_lastSavedId == null) return;

    isFavorite = !isFavorite;
    notifyListeners();

    await _historyRepo.toggleFavorite(_lastSavedId!, isFavorite);
  }

  /// Save the current result to history as type 'discover'.
  Future<void> _saveToHistory() async {
    if (result == null) return;

    final funFactsText =
        result!.funFacts.isNotEmpty ? result!.funFacts.join('\n') : null;

    final translation = Translation(
      type: 'discover',
      sourceText: query,
      translatedText: result!.description,
      sourceLanguage: 'en',
      targetLanguage: 'en',
      title: result!.title,
      context: funFactsText,
      createdAt: DateTime.now(),
    );

    _lastSavedId = await _historyRepo.insertTranslation(translation);
  }

  @override
  void dispose() {
    _isDisposed = true;
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
