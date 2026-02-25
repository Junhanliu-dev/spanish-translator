import 'package:flutter/material.dart';

import '../../core/storage/settings_service.dart';

/// Global theme mode state.
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({required SettingsService settingsService})
      : _settingsService = settingsService,
        _themeMode = settingsService.getThemeMode();

  final SettingsService _settingsService;

  ThemeMode _themeMode;

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    _settingsService.setThemeMode(mode);
    notifyListeners();
  }
}
