import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _biometricTokenKey = 'biometric_token';
  static const _biometricOwnerKey = 'biometry_owner_id';
  static const _savedEmailKey = 'saved_email';
  static const _rememberMeKey = 'remember_me';
  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const _welcomeSetupDonePrefix = 'welcome_setup_done_';
  static const _lastActiveAtKey = 'last_active_at';
  static const _pushInstallationKey = 'push_installation_id';

  static SharedPreferences? _prefs;
  static String? _tokenCache;
  static String? _refreshTokenCache;
  static Future<void> _tokenOperation = Future<void>.value();

  /// Initializes synchronous preferences. Must be called in main() before runApp().
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[StorageService] SharedPreferences init error: $e');
    }
  }

  static String? get cachedToken => _tokenCache;

  static Future<String> getPushInstallationId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final saved = prefs.getString(_pushInstallationKey);
    if (saved != null) return saved;
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await prefs.setString(_pushInstallationKey, id);
    return id;
  }

  static Future<String?> getToken() async {
    return _enqueueTokenRead(() async {
      if (_tokenCache != null) return _tokenCache;
      final token = await _storage.read(key: _tokenKey);
      _tokenCache = token;
      return token;
    });
  }

  static Future<String?> getRefreshToken() async {
    return _enqueueTokenRead(() async {
      if (_refreshTokenCache != null) return _refreshTokenCache;
      final token = await _storage.read(key: _refreshTokenKey);
      _refreshTokenCache = token;
      return token;
    });
  }

  static Future<void> saveTokenPair(String token, String? refreshToken) async {
    await _enqueueTokenOperation(() async {
      await _storage.write(key: _tokenKey, value: token);
      if (refreshToken == null) {
        await _storage.delete(key: _refreshTokenKey);
      } else {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
      _tokenCache = token;
      _refreshTokenCache = refreshToken;
    });
  }

  static Future<void> saveBiometricToken(String token) async {
    await _enqueueTokenOperation(
      () => _storage.write(key: _biometricTokenKey, value: token),
    );
  }

  static Future<void> saveBiometricOwner(String userId) async {
    await _enqueueTokenOperation(
      () => _storage.write(key: _biometricOwnerKey, value: userId),
    );
  }

  static Future<String?> getBiometricOwner() async {
    return _enqueueTokenRead(() => _storage.read(key: _biometricOwnerKey));
  }

  static Future<void> saveEmail(String email) async {
    await _storage.write(
      key: _savedEmailKey,
      value: email.trim().toLowerCase(),
    );
  }

  static Future<String?> getEmail() => _storage.read(key: _savedEmailKey);

  static Future<void> clearEmail() => _storage.delete(key: _savedEmailKey);

  static Future<String?> getBiometricToken() async {
    return _enqueueTokenRead(() => _storage.read(key: _biometricTokenKey));
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

  static String _welcomeSetupKey(String userId) =>
      '$_welcomeSetupDonePrefix$userId';

  static bool hasSeenWelcomeSetupSync(String userId) {
    return _prefs?.getBool(_welcomeSetupKey(userId)) ?? false;
  }

  static Future<void> setWelcomeSetupDone(String userId) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setBool(_welcomeSetupKey(userId), true);
    } catch (e) {
      debugPrint('[StorageService] setWelcomeSetupDone error: $e');
    }
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
    await _enqueueTokenOperation(() async {
      _tokenCache = null;
      _refreshTokenCache = null;
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
    });
  }

  static Future<void> clearTokenIf(String token) async {
    await _enqueueTokenOperation(() async {
      if (_tokenCache == token ||
          await _storage.read(key: _tokenKey) == token) {
        _tokenCache = null;
        await _storage.delete(key: _tokenKey);
      }
    });
  }

  static Future<void> clearRefreshTokenIf(String token) async {
    await _enqueueTokenOperation(() async {
      if (_refreshTokenCache == token ||
          await _storage.read(key: _refreshTokenKey) == token) {
        _refreshTokenCache = null;
        await _storage.delete(key: _refreshTokenKey);
      }
    });
  }

  static Future<void> _enqueueTokenOperation(
    Future<void> Function() operation,
  ) {
    final result = _tokenOperation.then((_) => operation());
    _tokenOperation = result.then<void>((_) {}, onError: (error, stack) {});
    return result;
  }

  static Future<void> clearBiometricToken() async {
    await _enqueueTokenOperation(() async {
      await _storage.delete(key: _biometricTokenKey);
      await _storage.delete(key: _biometricOwnerKey);
    });
  }

  static Future<T> _enqueueTokenRead<T>(Future<T> Function() operation) {
    final result = _tokenOperation.then((_) => operation());
    _tokenOperation = result.then<void>((_) {}, onError: (error, stack) {});
    return result;
  }
}
