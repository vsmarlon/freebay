import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL não definida. Compile com '
        '--dart-define=API_BASE_URL=https://api.exemplo.com',
      );
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:3000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:3000';
    }
  }

  static bool get isUsingApiOverride => _apiBaseUrlOverride.isNotEmpty;

  static bool get isSecureTransport => apiBaseUrl.startsWith('https://');
}
