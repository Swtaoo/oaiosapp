import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 封装 - 用于非敏感数据的本地存储
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // String
  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  // Bool
  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  // Int
  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  // Remove
  Future<bool> remove(String key) => _prefs.remove(key);

  // Clear
  Future<bool> clear() => _prefs.clear();
}

final localStorageProvider = FutureProvider<LocalStorageService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LocalStorageService(prefs);
});
