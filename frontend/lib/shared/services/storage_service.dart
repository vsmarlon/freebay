import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _isGuestKey = 'is_guest';
  static const _rememberMeKey = 'remember_me';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> saveIsGuest(bool isGuest) async {
    await _storage.write(key: _isGuestKey, value: isGuest.toString());
  }

  static Future<bool> getIsGuest() async {
    final value = await _storage.read(key: _isGuestKey);
    return value == 'true';
  }

  static Future<void> saveRememberMe(bool rememberMe) async {
    await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
  }

  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _isGuestKey);
  }
}
