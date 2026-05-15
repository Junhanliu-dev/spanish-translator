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
/// notifiers. Stateful so that we can detach the long-lived connectivity
/// subscription when the app is torn down.
class LinguaViajeApp extends StatefulWidget {
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
  State<LinguaViajeApp> createState() => _LinguaViajeAppState();
}

class _LinguaViajeAppState extends State<LinguaViajeApp> {
  @override
  void dispose() {
    widget.connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeNotifier,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'LinguaViaje',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: widget.themeNotifier.themeMode,
          routerConfig: widget.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
