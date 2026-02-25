import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/app_language.dart';
import '../../shared/models/target_language.dart';

/// SharedPreferences wrapper for user preferences.
class SettingsService {
  late final SharedPreferences _prefs;

  // Keys
  static const _sourceLanguageKey = 'source_language';
  static const _targetLanguageKey = 'target_language';
  static const _themeModeKey = 'theme_mode';
  static const _appLocaleKey = 'app_locale';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _firstLaunchKey = 'first_launch';

  /// Initialize SharedPreferences. Must be called before any other method.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the source language preference.
  AppLanguage getSourceLanguage() {
    final code = _prefs.getString(_sourceLanguageKey);
    if (code == null) return AppLanguage.english;
    return AppLanguage.fromCode(code);
  }

  /// Save the source language preference.
  void setSourceLanguage(AppLanguage lang) {
    _prefs.setString(_sourceLanguageKey, lang.code);
  }

  /// Get the target language preference.
  TargetLanguage getTargetLanguage() {
    final code = _prefs.getString(_targetLanguageKey);
    if (code == null) return TargetLanguage.spanish;
    return TargetLanguage.fromCode(code);
  }

  /// Save the target language preference.
  void setTargetLanguage(TargetLanguage lang) {
    _prefs.setString(_targetLanguageKey, lang.code);
  }

  /// Get the theme mode preference.
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Save the theme mode preference.
  void setThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    _prefs.setString(_themeModeKey, value);
  }

  /// Get the app locale preference (e.g., 'en' or 'zh').
  String getAppLocale() {
    return _prefs.getString(_appLocaleKey) ?? 'en';
  }

  /// Save the app locale preference.
  void setAppLocale(String locale) {
    _prefs.setString(_appLocaleKey, locale);
  }

  /// Check whether onboarding has been completed.
  bool isOnboardingComplete() {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as complete or incomplete.
  void setOnboardingComplete(bool value) {
    _prefs.setBool(_onboardingCompleteKey, value);
  }

  /// Check whether this is the first launch.
  bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  /// Mark first launch as handled.
  void setFirstLaunch(bool value) {
    _prefs.setBool(_firstLaunchKey, value);
  }
}
