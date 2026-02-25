import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage for API key management.
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _apiKeyKey = 'openai_api_key';

  /// Retrieve the stored API key, or null if none exists.
  Future<String?> getApiKey() async {
    return _storage.read(key: _apiKeyKey);
  }

  /// Store a new API key securely.
  Future<void> setApiKey(String key) async {
    await _storage.write(key: _apiKeyKey, value: key);
  }

  /// Delete the stored API key.
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }

  /// Check whether an API key is stored.
  Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _apiKeyKey);
    return key != null && key.isNotEmpty;
  }
}
