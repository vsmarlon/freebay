import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:freebay/shared/l10n/app_locale_resolution.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class BiometricKeyService {
  static const _channel = MethodChannel('com.freebay.app/biometric_key');

  Map<String, String> get _prompt {
    final strings = lookupAppLocalizations(
      resolveAppLocale(WidgetsBinding.instance.platformDispatcher.locales),
    );
    return {
      'reason': strings.stepUpConfirmTitle,
      'cancel': strings.commonCancel,
    };
  }

  Future<String> generatePublicKey() async {
    final key = await _channel.invokeMethod<String>('generate');
    if (key == null) throw PlatformException(code: 'key_generation_failed');
    return key;
  }

  Future<String> sign(String challenge) async {
    final signature = await _channel.invokeMethod<String>('sign', {
      'challenge': challenge,
      ..._prompt,
    });
    if (signature == null) throw PlatformException(code: 'sign_failed');
    return signature;
  }

  Future<bool> hasKey() async {
    try {
      return await _channel.invokeMethod<bool>('hasKey') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> delete() => _channel.invokeMethod<void>('delete');

  Future<void> clearVault() => _channel.invokeMethod<void>('clearVault');

  Future<void> writeVault(String token) =>
      _channel.invokeMethod<void>('writeVault', {'token': token, ..._prompt});

  Future<String?> readVault() =>
      _channel.invokeMethod<String>('readVault', _prompt);
}
