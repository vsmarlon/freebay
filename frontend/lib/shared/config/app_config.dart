import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _stripePublishableKeyDefine = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String _sentryDsnDefine = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static const String _googleServerClientIdDefine = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String get googleServerClientId {
    if (_googleServerClientIdDefine.isNotEmpty) {
      return _googleServerClientIdDefine;
    }
    return dotenv.maybeGet('GOOGLE_SERVER_CLIENT_ID') ?? '';
  }

  static String get stripePublishableKey {
    if (_stripePublishableKeyDefine.isNotEmpty) {
      return _stripePublishableKeyDefine;
    }
    return dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ?? '';
  }

  static String get sentryDsn {
    if (_sentryDsnDefine.isNotEmpty) {
      return _sentryDsnDefine;
    }
    return dotenv.maybeGet('SENTRY_DSN') ?? '';
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) {
      return _apiBaseUrlDefine;
    }
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL não definida. Adicione ao .env ou passe via '
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
      case TargetPlatform.fuchsia:
        return 'http://localhost:3000';
    }
  }

  static bool get isUsingApiOverride =>
      _apiBaseUrlDefine.isNotEmpty ||
      (dotenv.maybeGet('API_BASE_URL')?.isNotEmpty ?? false);

  static bool get isSecureTransport => apiBaseUrl.startsWith('https://');
}
