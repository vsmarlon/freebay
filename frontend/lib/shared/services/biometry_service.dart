import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freebay/shared/services/storage_service.dart';

const String _biometryEnabledKey = 'biometry_enabled';
const String _biometryPromptedKey = 'biometry_prompted';

class BiometryService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Check if biometrics are available on the device.
  Future<bool> isAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final enrolledBiometrics = await _localAuth.getAvailableBiometrics();
      return canCheckBiometrics &&
          isDeviceSupported &&
          enrolledBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Return the preferred biometric type, if any.
  Future<BiometryType?> getBiometryType() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometryType.face;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometryType.fingerprint;
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return BiometryType.iris;
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Prompt the user for biometric authentication.
  /// Returns true if the user authenticated successfully.
  Future<bool> authenticate({
    String reason = 'Autentique para continuar',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }

  // ── Biometric-enabled preference ──────────────────────────────────────

  Future<bool> isEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometryEnabledKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _biometryEnabledKey,
        value: enabled.toString(),
      );
    } catch (_) {
      // Silently fail
    }
  }

  Future<bool> hasPrompted() async {
    try {
      final value = await _secureStorage.read(key: _biometryPromptedKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setHasPrompted(bool prompted) async {
    try {
      await _secureStorage.write(
        key: _biometryPromptedKey,
        value: prompted.toString(),
      );
    } catch (_) {
      // Silently fail
    }
  }

  // ── Biometric token storage (migrated to StorageService) ─────────────
  // The token is actually stored via StorageService, but we keep a helper
  // here to check if it exists alongside the enabled flag.

  Future<bool> hasCredentials() async {
    final token = await StorageService.getBiometricToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearCredentials() async {
    await setEnabled(false);
    await StorageService.clearBiometricToken();
  }

  Future<void> clearState() async {
    await clearCredentials();
    await setHasPrompted(false);
  }
}

enum BiometryType { face, fingerprint, iris }
