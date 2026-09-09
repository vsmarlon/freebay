import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _biometricTokenKey = 'biometric_token';
  static const _rememberMeKey = 'remember_me';
  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const _lastActiveAtKey = 'last_active_at';

  static SharedPreferences? _prefs;
  static String? _tokenCache;
  static String? _refreshTokenCache;

  /// Initializes synchronous preferences. Must be called in main() before runApp().
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[StorageService] SharedPreferences init error: $e');
    }
  }

  static Future<void> saveToken(String token) async {
    _tokenCache = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  static String? get cachedToken => _tokenCache;

  static Future<String?> getToken() async {
    if (_tokenCache != null) return _tokenCache;
    final token = await _storage.read(key: _tokenKey);
    _tokenCache = token;
    return token;
  }

  static Future<void> saveRefreshToken(String token) async {
    _refreshTokenCache = token;
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    if (_refreshTokenCache != null) return _refreshTokenCache;
    final token = await _storage.read(key: _refreshTokenKey);
    _refreshTokenCache = token;
    return token;
  }

  static Future<void> saveBiometricToken(String token) async {
    await _storage.write(key: _biometricTokenKey, value: token);
  }

  static Future<String?> getBiometricToken() async {
    return await _storage.read(key: _biometricTokenKey);
  }

  static Future<void> saveRememberMe(bool rememberMe) async {
    if (_prefs != null) {
      await _prefs!.setBool(_rememberMeKey, rememberMe);
    } else {
      await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
    }
  }

  static Future<bool> getRememberMe() async {
    if (_prefs != null) {
      return _prefs!.getBool(_rememberMeKey) ?? true;
    }
    final value = await _storage.read(key: _rememberMeKey);
    return value != 'false';
  }

  static bool hasSeenOnboardingSync() {
    return _prefs?.getBool(_hasSeenOnboardingKey) ?? false;
  }

  static DateTime? lastActiveAtSync() {
    final millis = _prefs?.getInt(_lastActiveAtKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static void touchLastActiveAt() {
    _prefs?.setInt(_lastActiveAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearLastActiveAt() async {
    await _prefs?.remove(_lastActiveAtKey);
  }

  static Future<bool> getHasSeenOnboarding() async {
    if (_prefs != null) {
      return _prefs!.getBool(_hasSeenOnboardingKey) ?? false;
    }
    final value = await _storage.read(key: _hasSeenOnboardingKey);
    return value == 'true';
  }

  static Future<void> setHasSeenOnboarding() async {
    if (_prefs != null) {
      await _prefs!.setBool(_hasSeenOnboardingKey, true);
    }
    try {
      await _storage.write(key: _hasSeenOnboardingKey, value: 'true');
    } catch (e) {
      debugPrint(
        '[StorageService] setHasSeenOnboarding secure write error: $e',
      );
    }
  }

  static Future<void> clearTokens() async {
    _tokenCache = null;
    _refreshTokenCache = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> clearBiometricToken() async {
    await _storage.delete(key: _biometricTokenKey);
  }
}
