import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:freebay/shared/l10n/app_locale_resolution.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class BiometricKeyService {
  static const _channel = MethodChannel('com.freebay.app/biometric_key');
  // ponytail: app-wide locale applies to app-supplied native prompt strings.
  static String _localePreference = 'system';

  static void setLocalePreference(String preference) {
    _localePreference = switch (preference) {
      'pt_BR' || 'en' => preference,
      _ => 'system',
    };
  }

  Map<String, String> _prompt(String? localePreference) {
    final strings = lookupAppLocalizations(
      resolveAppLocale(
        WidgetsBinding.instance.platformDispatcher.locales,
        preference: localePreference ?? _localePreference,
      ),
    );
    return {'reason': strings.stepUpBiometrics, 'cancel': strings.commonCancel};
  }

  Future<String> generatePublicKey() async {
    final key = await _channel.invokeMethod<String>('generate');
    if (key == null) throw PlatformException(code: 'key_generation_failed');
    return key;
  }

  Future<String> sign(String challenge) async {
    final signature = await _channel.invokeMethod<String>('sign', {
      'challenge': challenge,
      ..._prompt(null),
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

  Future<void> writeVault(String token) => _channel.invokeMethod<void>(
    'writeVault',
    {'token': token, ..._prompt(null)},
  );

  Future<String?> readVault() =>
      _channel.invokeMethod<String>('readVault', _prompt(null));
}
