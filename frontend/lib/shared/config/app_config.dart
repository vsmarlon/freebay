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
    return _googleServerClientIdDefine;
  }

  static String get stripePublishableKey {
    return _stripePublishableKeyDefine;
  }

  static String get sentryDsn {
    return _sentryDsnDefine;
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) {
      final uri = Uri.tryParse(_apiBaseUrlDefine);
      final valid =
          uri != null &&
          uri.hasAuthority &&
          uri.host.isNotEmpty &&
          (kDebugMode || uri.scheme == 'https');
      if (valid) return _apiBaseUrlDefine;
      ErrorReporter.report(
        'config',
        StateError('API_BASE_URL is invalid for this build mode.'),
      );
      return '';
    }

    if (kReleaseMode || kProfileMode) {
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
