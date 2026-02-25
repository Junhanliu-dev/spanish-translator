import 'package:flutter/foundation.dart';

import '../../core/storage/settings_service.dart';
import '../models/app_language.dart';
import '../models/target_language.dart';

/// Global state for source and target language preferences.
/// Shared across all translation features.
class LanguagePrefsNotifier extends ChangeNotifier {
  LanguagePrefsNotifier({required SettingsService settingsService})
      : _settingsService = settingsService,
        _sourceLanguage = settingsService.getSourceLanguage(),
        _targetLanguage = settingsService.getTargetLanguage();

  final SettingsService _settingsService;

  AppLanguage _sourceLanguage;

  /// The user's source (spoken) language.
  AppLanguage get sourceLanguage => _sourceLanguage;
  set sourceLanguage(AppLanguage lang) {
    _sourceLanguage = lang;
    _settingsService.setSourceLanguage(lang);
    notifyListeners();
  }

  TargetLanguage _targetLanguage;

  /// The user's target (translation) language.
  TargetLanguage get targetLanguage => _targetLanguage;
  set targetLanguage(TargetLanguage lang) {
    _targetLanguage = lang;
    _settingsService.setTargetLanguage(lang);
    notifyListeners();
  }
}
