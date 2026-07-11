import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _biometryEnabledKey = 'biometry_enabled';

class BiometryService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<bool> isAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

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

  Future<bool> authenticate({
    String reason = 'Autentique para continuar',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometryEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _biometryEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      // Silently fail
    }
  }
}

enum BiometryType { face, fingerprint, iris }
