import 'package:flutter/foundation.dart';
import 'package:freebay/shared/services/error_reporter.dart';

class AppConfig {
  AppConfig._();

  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _stripePublishableKeyDefine = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static const String _sentryDsnDefine = String.fromEnvironment('SENTRY_DSN');

  static const String _googleServerClientIdDefine = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const String paymentMerchantCountryCode = String.fromEnvironment(
    'PAYMENT_MERCHANT_COUNTRY_CODE',
  );

  static const String applePayMerchantId = String.fromEnvironment(
    'APPLE_PAY_MERCHANT_ID',
  );

  static const bool googlePayTestEnvironment = bool.fromEnvironment(
    'GOOGLE_PAY_TEST_ENV',
  );

  static const bool googlePayProductionEnabled = bool.fromEnvironment(
    'GOOGLE_PAY_PRODUCTION_ENABLED',
  );

  static String get googleServerClientId {
    if (_googleServerClientIdDefine.isNotEmpty) {
      return _googleServerClientIdDefine;
    }
    if (kReleaseMode) return '';
    // ponytail: public OAuth Web client, same as android/app/google-services.json.
    // Dev/profile default so plain `flutter run [--profile]` gets Google sign-in;
    // explicit --dart-define always wins and release never uses this default.
    return _devGoogleServerClientId;
  }

  static const String _devGoogleServerClientId =
      '822277156637-440jps3kl7sdqjtb1548dmapntqp04ef.apps.googleusercontent.com';

  static String get stripePublishableKey {
    return _stripePublishableKeyDefine;
  }

  static String get sentryDsn {
    return _sentryDsnDefine;
  }

  static bool isAllowedApiBaseUrl(String value, {required bool isRelease}) {
    if (value.codeUnits.any((unit) => unit <= 0x1f || unit == 0x7f)) {
      return false;
    }
    final uri = Uri.tryParse(value);
    // Uri drops empty userinfo, so also check the raw authority delimiter.
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        RegExp(r'^https?://[^/?#]*@', caseSensitive: false).hasMatch(value)) {
      return false;
    }
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        !isRelease &&
        _isLoopbackOrPrivateIpv4(uri.host);
  }

  static bool _isLoopbackOrPrivateIpv4(String host) {
    final normalizedHost = host.toLowerCase();
    if (normalizedHost == 'localhost' || normalizedHost == '::1') return true;
    final parts = normalizedHost.split('.');
    if (parts.length != 4) return false;
    final octets = <int>[];
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null ||
          octet < 0 ||
          octet > 255 ||
          (part.length > 1 && part.startsWith('0'))) {
        return false;
      }
      octets.add(octet);
    }
    return octets[0] == 127 ||
        octets[0] == 10 ||
        (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
        (octets[0] == 192 && octets[1] == 168);
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) {
      if (isAllowedApiBaseUrl(_apiBaseUrlDefine, isRelease: kReleaseMode)) {
        return _apiBaseUrlDefine;
      }
      ErrorReporter.report(
        'config',
        StateError('API_BASE_URL is invalid for this build mode.'),
      );
      return '';
    }

    if (kReleaseMode) {
      ErrorReporter.report(
        'config',
        StateError(
          'API_BASE_URL não definida. Passe via '
          '--dart-define=API_BASE_URL=https://api.exemplo.com',
        ),
      );
      return '';
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://localhost:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:3000';
    }
  }

  static bool get isUsingApiOverride => _apiBaseUrlDefine.isNotEmpty;

  static bool get isSecureTransport => apiBaseUrl.startsWith('https://');
}
