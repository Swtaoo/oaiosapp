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
///
/// 内存缓存策略: token / refreshToken / userInfo 首次从加密存储读取后缓存在内存，
/// 后续读取直接返回内存值，避免每次请求都经过平台通道 + 加密解密。
class SecureStorageService {
  final FlutterSecureStorage _storage;

  // 内存缓存 — 消除 QueuedInterceptor 中重复的加密读取开销
  String? _cachedToken;
  String? _cachedRefreshToken;
  String? _cachedUserInfo;
  bool _tokenLoaded = false;
  bool _refreshTokenLoaded = false;
  bool _userInfoLoaded = false;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  // Token
  Future<String?> getToken() async {
    if (_tokenLoaded) return _cachedToken;
    _cachedToken = await _storage.read(key: StorageKeys.token);
    _tokenLoaded = true;
    return _cachedToken;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    _tokenLoaded = true;
    await _storage.write(key: StorageKeys.token, value: token);
  }

  Future<void> deleteToken() async {
    _cachedToken = null;
    _tokenLoaded = true;
    await _storage.delete(key: StorageKeys.token);
  }

  // Refresh Token
  Future<String?> getRefreshToken() async {
    if (_refreshTokenLoaded) return _cachedRefreshToken;
    _cachedRefreshToken = await _storage.read(key: StorageKeys.refreshToken);
    _refreshTokenLoaded = true;
    return _cachedRefreshToken;
  }

  Future<void> setRefreshToken(String token) async {
    _cachedRefreshToken = token;
    _refreshTokenLoaded = true;
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  // User Info (JSON string)
  Future<String?> getUserInfo() async {
    if (_userInfoLoaded) return _cachedUserInfo;
    _cachedUserInfo = await _storage.read(key: StorageKeys.userInfo);
    _userInfoLoaded = true;
    return _cachedUserInfo;
  }

  Future<void> setUserInfo(String json) async {
    _cachedUserInfo = json;
    _userInfoLoaded = true;
    await _storage.write(key: StorageKeys.userInfo, value: json);
  }

  // Clear all
  Future<void> clearAll() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUserInfo = null;
    _tokenLoaded = true;
    _refreshTokenLoaded = true;
    _userInfoLoaded = true;
    await _storage.deleteAll();
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
