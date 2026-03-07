import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage for API key management.
///
/// Handles Android Keystore corruption gracefully — if the encrypted storage
/// can't be read (e.g. after reinstall or OS update), all operations degrade
/// to no-ops and the user is prompted to re-enter their API key.
class SecureStorageService {
  static const _apiKeyKey = 'openai_api_key';

  FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _corrupted = false;

  /// Retrieve the stored API key, or null if none exists.
  Future<String?> getApiKey() async {
    if (_corrupted) return null;
    try {
      return await _storage.read(key: _apiKeyKey);
    } on Exception {
      await _resetCorruptedStorage();
      return null;
    }
  }

  /// Store a new API key securely.
  Future<void> setApiKey(String key) async {
    if (_corrupted) {
      // Retry with a fresh storage instance after corruption reset.
      _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      _corrupted = false;
    }
    try {
      await _storage.write(key: _apiKeyKey, value: key);
    } on Exception {
      await _resetCorruptedStorage();
    }
  }

  /// Delete the stored API key.
  Future<void> deleteApiKey() async {
    if (_corrupted) return;
    try {
      await _storage.delete(key: _apiKeyKey);
    } on Exception {
      await _resetCorruptedStorage();
    }
  }

  /// Check whether an API key is stored.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<void> _resetCorruptedStorage() async {
    _corrupted = true;
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Storage is completely unrecoverable — that's OK,
      // _corrupted flag prevents further access attempts.
    }
  }
}
