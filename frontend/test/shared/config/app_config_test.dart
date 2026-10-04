import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads only build-time public configuration', () {
    expect(AppConfig.googleServerClientId, isEmpty);
    expect(AppConfig.stripePublishableKey, isEmpty);
    expect(AppConfig.sentryDsn, isEmpty);
    expect(AppConfig.isUsingApiOverride, isFalse);
    expect(AppConfig.apiBaseUrl, 'http://localhost:3000');
    expect(AppConfig.isSecureTransport, isFalse);
  });
}
