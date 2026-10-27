import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'jwt_token';
  static const _userRoleKey = 'user_role';
  static const _shopNameKey = 'shop_name';
  static const _userNameKey = 'user_name';
  static const _languageKey = 'app_language';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> clearAuth() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await prefs.remove(_shopNameKey);
    await prefs.remove(_userNameKey);
  }

  Future<void> saveUserMeta({required String role, required String shopName, required String userName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_shopNameKey, shopName);
    await prefs.setString(_userNameKey, userName);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<String?> getShopName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_shopNameKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static const _cameraFacingKey = 'preferred_camera_facing';

  Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  Future<void> savePreferredCamera(String facing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cameraFacingKey, facing);
  }

  Future<String> getPreferredCamera() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cameraFacingKey) ?? 'back';
  }
}

