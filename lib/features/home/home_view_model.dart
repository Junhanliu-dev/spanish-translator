import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/storage/history_repository.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/storage/settings_service.dart';
import '../../shared/models/translation.dart';

/// ViewModel for the Home screen.
///
/// Manages recent translations, API key state, first-launch greeting,
/// and permission status for feature card guards.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required HistoryRepository historyRepo,
    required SecureStorageService secureStorage,
    required SettingsService settingsService,
  })  : _historyRepo = historyRepo,
        _secureStorage = secureStorage,
        _settingsService = settingsService;

  final HistoryRepository _historyRepo;
  final SecureStorageService _secureStorage;
  final SettingsService _settingsService;

  /// The 3 most recent translations.
  List<Translation> recentTranslations = [];

  /// Whether the user has an API key configured.
  bool hasApiKey = false;

  /// Whether this is the first launch (show greeting).
  bool isFirstLaunch = false;

  /// Whether microphone permission is granted.
  bool hasMicPermission = false;

  /// Whether camera permission is granted.
  bool hasCameraPermission = false;

  /// Whether the greeting banner has been dismissed.
  bool _greetingDismissed = false;

  /// Whether to show the greeting banner.
  bool get showGreeting => isFirstLaunch && !_greetingDismissed;

  /// Load home screen state from storage and check permissions.
  Future<void> init() async {
    hasApiKey = await _secureStorage.hasApiKey();
    isFirstLaunch = _settingsService.isFirstLaunch();

    await Future.wait([
      _loadRecentTranslations(),
      checkPermissions(),
    ]);

    notifyListeners();
  }

  Future<void> _loadRecentTranslations() async {
    try {
      recentTranslations = await _historyRepo.getRecentTranslations(limit: 3);
    } catch (_) {
      recentTranslations = [];
    }
  }

  /// Check and update microphone and camera permission states.
  Future<void> checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    final cameraStatus = await Permission.camera.status;

    hasMicPermission = micStatus.isGranted;
    hasCameraPermission = cameraStatus.isGranted;
    notifyListeners();
  }

  /// Mark the first-launch greeting banner as dismissed.
  void dismissGreeting() {
    _greetingDismissed = true;
    _settingsService.setFirstLaunch(false);
    notifyListeners();
  }

  /// Refresh recent translations (call when returning to home).
  Future<void> refresh() async {
    await _loadRecentTranslations();
    hasApiKey = await _secureStorage.hasApiKey();
    notifyListeners();
  }
}
