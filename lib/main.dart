import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/openai_client.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/router/app_router.dart';
import 'core/service_locator.dart';
import 'core/storage/history_repository.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/storage/settings_service.dart';
import 'shared/notifiers/language_prefs_notifier.dart';
import 'shared/notifiers/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = SecureStorageService();
  final settingsService = SettingsService();
  final historyRepo = HistoryRepository();
  final connectivityService = ConnectivityService();

  // Parallelize the two inits we MUST have before runApp:
  //   - settingsService: notifiers read it synchronously in their ctors
  //   - historyRepo: late-final `_db` must be wired before any screen reads
  // (~halves the sequential await chain on cold start.)
  await Future.wait([
    settingsService.init(),
    historyRepo.init(),
  ]);

  // Connectivity defaults to "online" until its first probe returns, so we
  // can kick init off in the background without blocking first paint.
  unawaited(connectivityService.init());

  // Start with an empty-key client; seed it from the keychain / --dart-define
  // asynchronously. The first user-facing action that hits the API happens
  // well after runApp, so this platform-channel read stays off the cold path.
  final apiClient = OpenAIClient(apiKey: '');
  unawaited(_seedApiKey(secureStorage, apiClient));

  final languagePrefs =
      LanguagePrefsNotifier(settingsService: settingsService);
  final themeNotifier = ThemeNotifier(settingsService: settingsService);

  ServiceLocator.apiClient = apiClient;
  ServiceLocator.secureStorage = secureStorage;
  ServiceLocator.settingsService = settingsService;
  ServiceLocator.historyRepo = historyRepo;
  ServiceLocator.connectivityService = connectivityService;
  ServiceLocator.languagePrefs = languagePrefs;
  ServiceLocator.themeNotifier = themeNotifier;

  final onboardingComplete = settingsService.isOnboardingComplete();

  final router = createRouter(
    onboardingComplete: onboardingComplete,
  );

  runApp(
    LinguaViajeApp(
      router: router,
      apiClient: apiClient,
      secureStorage: secureStorage,
      settingsService: settingsService,
      historyRepo: historyRepo,
      connectivityService: connectivityService,
      languagePrefs: languagePrefs,
      themeNotifier: themeNotifier,
    ),
  );
}

/// Seed the API key from the keychain (or compile-time env as a fallback).
///
/// Runs post-`runApp`; until it completes, the client's auth header is empty
/// and any API call throws [ApiKeyException] — which the UI already handles
/// by prompting the user to add a key in Settings.
Future<void> _seedApiKey(
  SecureStorageService secureStorage,
  OpenAIClient apiClient,
) async {
  var apiKey = await secureStorage.getApiKey();
  if (apiKey == null || apiKey.isEmpty) {
    const envKey = String.fromEnvironment('OPENAI_API_KEY');
    if (envKey.isNotEmpty) {
      await secureStorage.setApiKey(envKey);
      apiKey = envKey;
    }
  }
  if (apiKey != null && apiKey.isNotEmpty) {
    apiClient.updateApiKey(apiKey);
  }
}
