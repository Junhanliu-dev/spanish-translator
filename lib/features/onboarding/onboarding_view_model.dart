import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/openai_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/storage/settings_service.dart';
import '../../shared/models/app_language.dart';
import '../../shared/models/target_language.dart';

/// ViewModel for the onboarding flow.
///
/// Manages state across API key setup, language preferences,
/// permissions, and tutorial pages.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required SecureStorageService secureStorage,
    required SettingsService settingsService,
    required OpenAIClient apiClient,
  })  : _secureStorage = secureStorage,
        _settingsService = settingsService,
        _apiClient = apiClient;

  final SecureStorageService _secureStorage;
  final SettingsService _settingsService;
  final OpenAIClient _apiClient;

  /// Current onboarding step: 0 = API Key, 1 = Language, 2 = Permissions,
  /// 3 = Tutorial.
  int currentStep = 0;

  /// Raw API key input text.
  String? apiKeyInput;

  /// Whether validation is in progress.
  bool isValidatingKey = false;

  /// Validation error message, if any.
  String? keyValidationError;

  /// Whether the key has been validated.
  bool keyValidated = false;

  /// Selected source language.
  AppLanguage selectedSourceLanguage = AppLanguage.english;

  /// Selected target language.
  TargetLanguage selectedTargetLanguage = TargetLanguage.spanish;

  /// Selected app locale.
  String selectedLocale = 'en';

  /// Whether microphone permission is granted.
  bool micPermissionGranted = false;

  /// Whether camera permission is granted.
  bool cameraPermissionGranted = false;

  /// Current tutorial page index (0-2).
  int tutorialPage = 0;

  /// Validate and save API key.
  ///
  /// Returns true if the key is valid and saved.
  Future<bool> validateAndSaveKey(String key) async {
    if (!key.startsWith('sk-') || key.length < 20) {
      keyValidationError = 'API keys start with sk- and are 50+ characters';
      notifyListeners();
      return false;
    }

    isValidatingKey = true;
    keyValidationError = null;
    notifyListeners();

    _apiClient.updateApiKey(key);

    try {
      final valid = await _apiClient.validateApiKey();
      if (valid) {
        await _secureStorage.setApiKey(key);
        keyValidated = true;
        apiKeyInput = key;
        isValidatingKey = false;
        notifyListeners();
        return true;
      } else {
        keyValidationError =
            "Key didn't work — check it and try again";
        _apiClient.updateApiKey('');
      }
    } catch (_) {
      keyValidationError =
          "Couldn't verify key. Please check your connection.";
      _apiClient.updateApiKey('');
    }

    isValidatingKey = false;
    notifyListeners();
    return false;
  }

  /// Skip API key setup (user can add later in Settings).
  void skipApiKey() {
    keyValidated = false;
    apiKeyInput = null;
  }

  /// Update the selected source language.
  void setSourceLanguage(AppLanguage lang) {
    selectedSourceLanguage = lang;
    notifyListeners();
  }

  /// Update the selected target language.
  void setTargetLanguage(TargetLanguage lang) {
    selectedTargetLanguage = lang;
    notifyListeners();
  }

  /// Update the selected locale.
  void setLocale(String locale) {
    selectedLocale = locale;
    _settingsService.setAppLocale(locale);
    notifyListeners();
  }

  /// Save language preferences to storage.
  void saveLanguagePrefs() {
    _settingsService.setSourceLanguage(selectedSourceLanguage);
    _settingsService.setTargetLanguage(selectedTargetLanguage);
  }

  /// Request microphone permission.
  Future<void> requestMicPermission() async {
    final status = await Permission.microphone.request();
    micPermissionGranted = status.isGranted;
    notifyListeners();
  }

  /// Request camera permission.
  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    cameraPermissionGranted = status.isGranted;
    notifyListeners();
  }

  /// Set the tutorial page index.
  void setTutorialPage(int page) {
    tutorialPage = page;
    notifyListeners();
  }

  /// Complete onboarding: save preferences and mark as done.
  Future<void> completeOnboarding() async {
    saveLanguagePrefs();
    _settingsService.setOnboardingComplete(true);
    _settingsService.setFirstLaunch(true);
  }
}
