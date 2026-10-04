import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/onboarding/presentation/pages/welcome_setup_page.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _MockBiometryService extends BiometryService {
  int authenticationAttempts = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<bool> authenticate({
    String reason = 'Autentique para continuar',
  }) async {
    authenticationAttempts++;
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'declining welcome setup never prompts and completion stays user-keyed',
    (tester) async {
      final user = testUser(id: 'welcome-user', email: 'user@example.com');
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      final biometry = _MockBiometryService();
      final router = GoRouter(
        initialLocation: AppRoutes.welcome,
        routes: [
          GoRoute(
            path: AppRoutes.welcome,
            builder: (context, state) => const WelcomeSetupPage(),
          ),
          GoRoute(
            path: AppRoutes.feed,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => TestAuthController(user)),
            biometryServiceProvider.overrideWithValue(biometry),
            biometryAvailableProvider.overrideWith((ref) async => true),
            biometryEnabledProvider.overrideWith((ref) async => false),
          ],
          child: MaterialApp.router(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppLocalizations.of(
        tester.element(find.byType(WelcomeSetupPage)),
      );
      await tester.tap(find.text(strings.onboardingNotNow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.onboardingNotNow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.commonFinish));
      await tester.pumpAndSettle();

      expect(biometry.authenticationAttempts, 0);
      expect(StorageService.hasSeenWelcomeSetupSync(user.id), isTrue);
      expect(StorageService.hasSeenWelcomeSetupSync('another-user'), isFalse);
    },
  );
}
