import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/api/openai_client.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/storage/history_repository.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/storage/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/notifiers/language_prefs_notifier.dart';
import 'shared/notifiers/theme_notifier.dart';

/// Root widget for the LinguaViaje application.
///
/// Wires together [MaterialApp.router], the theme system, and global
/// notifiers.
class LinguaViajeApp extends StatelessWidget {
  const LinguaViajeApp({
    super.key,
    required this.router,
    required this.apiClient,
    required this.secureStorage,
    required this.settingsService,
    required this.historyRepo,
    required this.connectivityService,
    required this.languagePrefs,
    required this.themeNotifier,
  });

  final GoRouter router;
  final OpenAIClient apiClient;
  final SecureStorageService secureStorage;
  final SettingsService settingsService;
  final HistoryRepository historyRepo;
  final ConnectivityService connectivityService;
  final LanguagePrefsNotifier languagePrefs;
  final ThemeNotifier themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'LinguaViaje',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeNotifier.themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
