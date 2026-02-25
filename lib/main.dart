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

  // Initialize core services.
  final secureStorage = SecureStorageService();
  final settingsService = SettingsService();
  await settingsService.init();
  final historyRepo = HistoryRepository();
  await historyRepo.init();
  final connectivityService = ConnectivityService();
  await connectivityService.init();

  // Create OpenAI client (may have no key yet).
  final apiKey = await secureStorage.getApiKey();
  final apiClient = OpenAIClient(apiKey: apiKey ?? '');

  // Create global notifiers.
  final languagePrefs =
      LanguagePrefsNotifier(settingsService: settingsService);
  final themeNotifier = ThemeNotifier(settingsService: settingsService);

  // Populate the service locator.
  ServiceLocator.apiClient = apiClient;
  ServiceLocator.secureStorage = secureStorage;
  ServiceLocator.settingsService = settingsService;
  ServiceLocator.historyRepo = historyRepo;
  ServiceLocator.connectivityService = connectivityService;
  ServiceLocator.languagePrefs = languagePrefs;
  ServiceLocator.themeNotifier = themeNotifier;

  // Check onboarding state.
  final onboardingComplete = settingsService.isOnboardingComplete();

  // Create router.
  final router = createRouter(
    hasApiKey: apiKey != null,
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
