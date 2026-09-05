import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig with dotenv', () {
    tearDown(() {
      dotenv.clean();
    });

    test('reads values from loaded dotenv when define is not set', () {
      dotenv.testLoad(
        fileInput: '''
API_BASE_URL=https://api.freebay.example.com
GOOGLE_SERVER_CLIENT_ID=test-google-client-id.apps.googleusercontent.com
STRIPE_PUBLISHABLE_KEY=pk_test_12345
SENTRY_DSN=https://sentry.example.com/123
''',
      );

      expect(AppConfig.apiBaseUrl, 'https://api.freebay.example.com');
      expect(
        AppConfig.googleServerClientId,
        'test-google-client-id.apps.googleusercontent.com',
      );
      expect(AppConfig.stripePublishableKey, 'pk_test_12345');
      expect(AppConfig.sentryDsn, 'https://sentry.example.com/123');
      expect(AppConfig.isUsingApiOverride, isTrue);
      expect(AppConfig.isSecureTransport, isTrue);
    });

    test('returns default fallback when dotenv is empty', () {
      dotenv.clean();

      expect(AppConfig.googleServerClientId, isEmpty);
      expect(AppConfig.stripePublishableKey, isEmpty);
      expect(AppConfig.sentryDsn, isEmpty);
      expect(AppConfig.apiBaseUrl, isNotEmpty);
    });
  });
}
