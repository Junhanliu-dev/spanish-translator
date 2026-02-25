import 'api/openai_client.dart';
import 'connectivity/connectivity_service.dart';
import 'storage/history_repository.dart';
import 'storage/secure_storage_service.dart';
import 'storage/settings_service.dart';
import '../shared/notifiers/language_prefs_notifier.dart';
import '../shared/notifiers/theme_notifier.dart';

/// Simple service locator. Initialized once in [main].
///
/// Screens can pull services from here for convenience. ViewModels accept
/// services as constructor parameters for testability.
class ServiceLocator {
  static late final OpenAIClient apiClient;
  static late final SecureStorageService secureStorage;
  static late final SettingsService settingsService;
  static late final HistoryRepository historyRepo;
  static late final ConnectivityService connectivityService;
  static late final LanguagePrefsNotifier languagePrefs;
  static late final ThemeNotifier themeNotifier;
}
