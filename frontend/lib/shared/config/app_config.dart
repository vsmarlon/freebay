import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freebay/shared/services/error_reporter.dart';

class AppConfig {
  AppConfig._();

  static String? _fromEnv(String key) =>
      dotenv.isInitialized ? dotenv.maybeGet(key) : null;

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

  static String get googleServerClientId {
    if (_googleServerClientIdDefine.isNotEmpty) {
      return _googleServerClientIdDefine;
    }
    return _fromEnv('GOOGLE_SERVER_CLIENT_ID') ?? '';
  }

  static String get stripePublishableKey {
    if (_stripePublishableKeyDefine.isNotEmpty) {
      return _stripePublishableKeyDefine;
    }
    return _fromEnv('STRIPE_PUBLISHABLE_KEY') ?? '';
  }

  static String get sentryDsn {
    if (_sentryDsnDefine.isNotEmpty) {
      return _sentryDsnDefine;
    }
    return _fromEnv('SENTRY_DSN') ?? '';
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) {
      return _apiBaseUrlDefine;
    }
    final fromEnv = _fromEnv('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    if (kReleaseMode) {
      ErrorReporter.report(
        'config',
        StateError(
          'API_BASE_URL não definida. Adicione ao .env ou passe via '
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

  static bool get isUsingApiOverride =>
      _apiBaseUrlDefine.isNotEmpty ||
      (_fromEnv('API_BASE_URL')?.isNotEmpty ?? false);

  static bool get isSecureTransport => apiBaseUrl.startsWith('https://');
}
