import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freebay/shared/services/biometric_key_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _biometricTokenKey = 'biometric_token';
  static const _biometricOwnerKey = 'biometry_owner_id';
  static const _biometricVaultPresentKey = 'biometric_auth_v1_present';
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
  static const _userCacheBoxName = 'user_cache_v1';
  static const _maxCachedJsonBytes = 512 * 1024;
  static int _cacheGeneration = 0;
  static Future<void> _cacheOperation = Future<void>.value();
  static Box<String>? _userCacheBox;
  static Future<Box<String>>? _userCacheOpening;
  static bool _cacheStoreEnabled = false;

  /// Initializes synchronous preferences. Must be called in main() before runApp().
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[StorageService] SharedPreferences init error: $e');
    }
  }

  static Future<Box<String>> _cacheBox() async {
    final opened = _userCacheBox;
    if (opened != null && opened.isOpen) return opened;
    _userCacheBox = null;
    if (opened != null) _userCacheOpening = null;
    final opening = _userCacheOpening ??= Hive.openBox<String>(
      _userCacheBoxName,
    );
    try {
      return _userCacheBox ??= await opening;
    } catch (_) {
      _userCacheOpening = null;
      rethrow;
    }
  }

  static String _userCacheKey(String userId, String key) =>
      '${Uri.encodeComponent(userId)}:$key';

  static Future<void> _deleteCachedEntry(String key, int generation) =>
      _enqueueCacheOperation(() async {
        if (generation != _cacheGeneration) return;
        try {
          await (await _cacheBox()).delete(key);
        } catch (_) {
          // An unavailable cache is already a miss.
        }
      });

  static Future<Map<String, Object?>?> readCachedJson({
    required String userId,
    required String key,
  }) async {
    if (!_cacheStoreEnabled) return null;
    final generation = _cacheGeneration;
    try {
      final encoded = (await _cacheBox()).get(_userCacheKey(userId, key));
      if (encoded == null) return null;
      if (utf8.encode(encoded).length > _maxCachedJsonBytes) {
        await _deleteCachedEntry(_userCacheKey(userId, key), generation);
        return null;
      }
      final decoded = jsonDecode(encoded);
      if (generation != _cacheGeneration) return null;
      if (decoded is! Map<String, dynamic>) {
        await _deleteCachedEntry(_userCacheKey(userId, key), generation);
        return null;
      }
      final envelopeVersion = decoded['version'];
      final payload = decoded['data'];
      if (envelopeVersion != 1 || payload is! Map<String, dynamic>) {
        await _deleteCachedEntry(_userCacheKey(userId, key), generation);
        return null;
      }
      return Map<String, Object?>.from(payload);
    } catch (_) {
      await _deleteCachedEntry(_userCacheKey(userId, key), generation);
      return null;
    }
  }

  static Future<void> writeCachedJson({
    required String userId,
    required String key,
    required Map<String, Object?> json,
  }) async {
    if (!_cacheStoreEnabled) return;
    final generation = _cacheGeneration;
    return _enqueueCacheOperation(() async {
      try {
        final encoded = jsonEncode({'version': 1, 'data': json});
        if (utf8.encode(encoded).length > _maxCachedJsonBytes) return;
        final box = await _cacheBox();
        if (generation != _cacheGeneration) return;
        await box.put(_userCacheKey(userId, key), encoded);
      } catch (_) {
        // Cache failures must not break the online journey.
      }
    });
  }

  static Future<void> clearUserCache({String? userId}) async {
    _cacheGeneration++;
    if (!_cacheStoreEnabled) return;
    await _enqueueCacheOperation(() async {
      try {
        final box = await _cacheBox();
        if (userId == null) {
          await box.clear();
        } else {
          final prefix = '${Uri.encodeComponent(userId)}:';
          await box.deleteAll(
            box.keys.where((key) => key.toString().startsWith(prefix)),
          );
        }
      } catch (_) {
        // Cache cleanup is best effort; it never changes credential storage.
      }
    });
  }

  static Future<void> _enqueueCacheOperation(
    Future<void> Function() operation,
  ) {
    final result = _cacheOperation.then((_) => operation());
    _cacheOperation = result.then<void>((_) {}, onError: (error, stack) {});
    return result;
  }

  static String? get cachedToken => _tokenCache;

  static void enableCacheStore() => _cacheStoreEnabled = true;

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
    await BiometricKeyService().writeVault(token);
    await _storage.write(key: _biometricVaultPresentKey, value: 'true');
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
    return BiometricKeyService().readVault();
  }

  static Future<bool> hasBiometricToken() =>
      _storage.containsKey(key: _biometricVaultPresentKey);

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
    await clearUserCache();
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
    try {
      await BiometricKeyService().clearVault();
    } finally {
      await _enqueueTokenOperation(() async {
        try {
          await _storage.delete(key: _biometricTokenKey);
        } finally {
          try {
            await _storage.delete(key: _biometricOwnerKey);
          } finally {
            await _storage.delete(key: _biometricVaultPresentKey);
          }
        }
      });
    }
  }

  static Future<void> restoreAuthenticationMetadata({
    required String? email,
    required bool rememberMe,
    required String? biometricOwner,
  }) async {
    if (email == null) {
      await clearEmail();
    } else {
      await saveEmail(email);
    }
    await saveRememberMe(rememberMe);
    await _enqueueTokenOperation(() async {
      if (biometricOwner == null) {
        await _storage.delete(key: _biometricOwnerKey);
      } else {
        await _storage.write(key: _biometricOwnerKey, value: biometricOwner);
      }
    });
  }

  static Future<T> _enqueueTokenRead<T>(Future<T> Function() operation) {
    final result = _tokenOperation.then((_) => operation());
    _tokenOperation = result.then<void>((_) {}, onError: (error, stack) {});
    return result;
  }
}
