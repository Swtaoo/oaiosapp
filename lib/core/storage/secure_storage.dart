import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储键名
class StorageKeys {
  StorageKeys._();
  static const String token = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userInfo = 'user_info';
}

/// 安全存储服务 - Token 使用 flutter_secure_storage 加密存储
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  // Token
  Future<String?> getToken() => _storage.read(key: StorageKeys.token);

  Future<void> setToken(String token) =>
      _storage.write(key: StorageKeys.token, value: token);

  Future<void> deleteToken() => _storage.delete(key: StorageKeys.token);

  // Refresh Token
  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  // User Info (JSON string)
  Future<String?> getUserInfo() => _storage.read(key: StorageKeys.userInfo);

  Future<void> setUserInfo(String json) =>
      _storage.write(key: StorageKeys.userInfo, value: json);

  // Clear all
  Future<void> clearAll() => _storage.deleteAll();
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
