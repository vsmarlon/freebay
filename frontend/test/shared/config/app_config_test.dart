import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('accepts HTTP only for local or private hosts outside release', () {
    const cases = <(String, bool, bool)>[
      ('http://localhost:3000', false, true),
      ('http://127.0.0.1:3000', false, true),
      ('http://10.0.2.2:3000', false, true),
      ('http://10.255.255.255:3000', false, true),
      ('http://172.16.0.1:3000', false, true),
      ('http://172.31.255.254:3000', false, true),
      ('http://192.168.1.2:3000', false, true),
      ('http://[::1]:3000', false, true),
      ('http://8.8.8.8:3000', false, false),
      ('http://172.32.0.1:3000', false, false),
      ('http://192.169.1.2:3000', false, false),
      ('http://backend.lan:3000', false, false),
      ('https://api.example.com', false, true),
      ('http://192.168.1.2:3000', true, false),
      ('https://api.example.com', true, true),
      ('ftp://192.168.1.2:3000', false, false),
      ('http:///missing-host', false, false),
      ('http://user:pass@192.168.1.2:3000', false, false),
      ('http://@192.168.1.2:3000', false, false),
      ('https://@api.example.com', true, false),
      ('https://api.example.com/api@v1?contact=dev@example.com', true, true),
      ('http://192.168.1.2:3000\n', false, false),
    ];

    for (final (url, isRelease, expected) in cases) {
      expect(
        AppConfig.isAllowedApiBaseUrl(url, isRelease: isRelease),
        expected,
        reason: '$url, release=$isRelease',
      );
    }
  });

  test('release URLs require HTTPS without embedded credentials', () {
    expect(
      AppConfig.isAllowedApiBaseUrl('https://api.example.com', isRelease: true),
      isTrue,
    );
    expect(
      AppConfig.isAllowedApiBaseUrl(
        'https://user:pass@api.example.com',
        isRelease: true,
      ),
      isFalse,
    );
  });

  test(
    'returns the configured URL exactly when the build policy accepts it',
    () {
      if (AppConfig.isUsingApiOverride) {
        final sourceScheme = const String.fromEnvironment('API_BASE_URL');
        final allowed = AppConfig.isAllowedApiBaseUrl(
          sourceScheme,
          isRelease: kReleaseMode,
        );
        expect(AppConfig.apiBaseUrl, allowed ? sourceScheme : '');
        expect(
          AppConfig.isSecureTransport,
          allowed && sourceScheme.startsWith('https://'),
        );
        return;
      }
      expect(AppConfig.googleServerClientId, isNotEmpty);
      expect(AppConfig.stripePublishableKey, isEmpty);
      expect(AppConfig.sentryDsn, isEmpty);
      expect(AppConfig.isUsingApiOverride, isFalse);
      expect(AppConfig.apiBaseUrl, 'http://localhost:3000');
      expect(AppConfig.isSecureTransport, isFalse);
    },
  );
}
