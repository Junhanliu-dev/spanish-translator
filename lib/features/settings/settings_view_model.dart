import 'package:flutter/material.dart';

import '../../core/api/openai_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/storage/settings_service.dart';
import '../../shared/models/app_language.dart';
import '../../shared/models/target_language.dart';
import '../../shared/notifiers/language_prefs_notifier.dart';
import '../../shared/notifiers/theme_notifier.dart';

/// Validation status for the API key.
enum ApiKeyStatus { valid, invalid, unverified }

/// ViewModel for the Settings screen.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required SecureStorageService secureStorage,
    required SettingsService settingsService,
    required OpenAIClient apiClient,
    required LanguagePrefsNotifier languagePrefs,
    required ThemeNotifier themeNotifier,
  })  : _secureStorage = secureStorage,
        _settingsService = settingsService,
        _apiClient = apiClient,
        _languagePrefs = languagePrefs,
        _themeNotifier = themeNotifier;

  final SecureStorageService _secureStorage;
  final SettingsService _settingsService;
  final OpenAIClient _apiClient;
  final LanguagePrefsNotifier _languagePrefs;
  final ThemeNotifier _themeNotifier;

  /// Whether an API key is stored.
  bool hasApiKey = false;

  /// Masked display of the API key (e.g., "sk-...abc4").
  String? maskedApiKey;

  /// Current validation status.
  ApiKeyStatus apiKeyStatus = ApiKeyStatus.unverified;

  /// Human-readable status message.
  String? apiKeyStatusMessage;

  /// Whether a validation call is in progress.
  bool isValidating = false;

  /// Whether the API key input field is in edit mode.
  bool isEditing = false;

  // Language accessors for the UI.
  AppLanguage get sourceLanguage => _languagePrefs.sourceLanguage;
  TargetLanguage get targetLanguage => _languagePrefs.targetLanguage;
  ThemeMode get themeMode => _themeNotifier.themeMode;
  String get appLocale => _settingsService.getAppLocale();

  /// Load current state from storage.
  Future<void> init() async {
    hasApiKey = await _secureStorage.hasApiKey();
    if (hasApiKey) {
      final key = await _secureStorage.getApiKey();
      if (key != null) {
        maskedApiKey = _maskKey(key);
      }
    }
    notifyListeners();
  }

  /// Save and validate a new API key.
  ///
  /// Returns true if the key was validated successfully.
  Future<bool> saveApiKey(String key) async {
    if (!key.startsWith('sk-') || key.length < 20) {
      apiKeyStatus = ApiKeyStatus.invalid;
      apiKeyStatusMessage = 'API keys start with sk- and are 50+ characters';
      notifyListeners();
      return false;
    }

    isValidating = true;
    notifyListeners();

    // Temporarily use new key for validation without persisting.
    final previousKey = await _secureStorage.getApiKey();
    _apiClient.updateApiKey(key);

    try {
      final valid = await _apiClient.validateApiKey();
      if (valid) {
        // Only persist after successful validation.
        await _secureStorage.setApiKey(key);
        hasApiKey = true;
        maskedApiKey = _maskKey(key);
        apiKeyStatus = ApiKeyStatus.valid;
        apiKeyStatusMessage = 'Validated successfully';
        isEditing = false;
      } else {
        // Restore previous key.
        _apiClient.updateApiKey(previousKey ?? '');
        apiKeyStatus = ApiKeyStatus.invalid;
        apiKeyStatusMessage =
            "This key didn't work — check it and try again";
      }
    } catch (_) {
      // Restore previous key on network failure.
      _apiClient.updateApiKey(previousKey ?? '');
      apiKeyStatus = ApiKeyStatus.unverified;
      apiKeyStatusMessage =
          "Couldn't verify key. Please check your connection.";
    }

    isValidating = false;
    notifyListeners();
    return apiKeyStatus == ApiKeyStatus.valid;
  }

  /// Verify the existing API key.
  Future<void> verifyApiKey() async {
    isValidating = true;
    notifyListeners();

    try {
      final valid = await _apiClient.validateApiKey();
      if (valid) {
        apiKeyStatus = ApiKeyStatus.valid;
        apiKeyStatusMessage = 'Validated successfully';
      } else {
        apiKeyStatus = ApiKeyStatus.invalid;
        apiKeyStatusMessage =
            "This key didn't work — check it and try again";
      }
    } catch (_) {
      apiKeyStatus = ApiKeyStatus.unverified;
      apiKeyStatusMessage =
          "Couldn't verify key. Please check your connection.";
    }

    isValidating = false;
    notifyListeners();
  }

  /// Toggle the edit mode for the API key.
  void toggleEditing() {
    isEditing = !isEditing;
    notifyListeners();
  }

  /// Change source language preference.
  void setSourceLanguage(AppLanguage lang) {
    _languagePrefs.sourceLanguage = lang;
    notifyListeners();
  }

  /// Change target language preference.
  void setTargetLanguage(TargetLanguage lang) {
    _languagePrefs.targetLanguage = lang;
    notifyListeners();
  }

  /// Change theme mode.
  void setThemeMode(ThemeMode mode) {
    _themeNotifier.themeMode = mode;
    notifyListeners();
  }

  /// Change app locale.
  void setAppLocale(String locale) {
    _settingsService.setAppLocale(locale);
    notifyListeners();
  }

  String _maskKey(String key) {
    if (key.length < 8) return '\u2022' * 8;
    final prefix = key.substring(0, 3);
    final suffix = key.substring(key.length - 4);
    return '$prefix${'\u2022' * 20}$suffix';
  }
}
