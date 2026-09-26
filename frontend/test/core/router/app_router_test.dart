import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _MockInitialAuthLoadingNotifier extends IsInitialAuthLoadingNotifier {
  @override
  bool build() => false;
}

class _MockHasSeenOnboardingNotifier extends HasSeenOnboardingNotifier {
  @override
  bool build() => true;
}

Future<void> _pumpRouter(WidgetTester tester, UserEntity? user) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isInitialAuthLoadingProvider.overrideWith(
          _MockInitialAuthLoadingNotifier.new,
        ),
        hasSeenOnboardingProvider.overrideWith(
          _MockHasSeenOnboardingNotifier.new,
        ),
        authControllerProvider.overrideWith(() => TestAuthController(user)),
      ],
      child: MaterialApp.router(routerConfig: appRouter),
    ),
  );

  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chat product route encodes both typed identifiers', () {
    final uri = Uri.parse(AppRoutes.chatNewWith('seller/1', 'product 2'));

    expect(uri.path, AppRoutes.chatNew);
    expect(uri.queryParameters['targetUserId'], 'seller/1');
    expect(uri.queryParameters['productId'], 'product 2');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    await StorageService.init();
  });

  testWidgets(
    'User without username (Google login) stays on completeProfile without redirect loop',
    (tester) async {
      final userWithoutUsername = testUser(
        id: '6c7ddf73-54a8-41d2-931b-4482f9d7c153',
        displayName: 'Wave LOL',
        email: 'wavegamer5k@gmail.com',
      );
      await _pumpRouter(tester, userWithoutUsername);

      // Complete profile page is shown without an error screen
      expect(
        appRouter.routeInformationProvider.value.uri.path,
        AppRoutes.completeProfile,
      );
      expect(find.text('Não foi possível abrir esta tela.'), findsNothing);
    },
  );

  testWidgets(
    'User with username and incomplete welcome setup redirects to welcome page',
    (tester) async {
      final userWithUsername = testUser(
        id: 'user-with-username',
        displayName: 'Wave LOL',
        email: 'wavegamer5k@gmail.com',
        username: 'wavegamer',
      );

      await _pumpRouter(tester, userWithUsername);

      expect(
        appRouter.routeInformationProvider.value.uri.path,
        AppRoutes.welcome,
      );
      expect(find.text('Não foi possível abrir esta tela.'), findsNothing);
    },
  );

  testWidgets(
    'User with username and completed welcome setup redirects to feed',
    (tester) async {
      const userId = 'user-fully-setup';
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        'welcome_setup_done_$userId': true,
      });
      await StorageService.init();

      final userFull = testUser(
        id: userId,
        displayName: 'Wave LOL',
        email: 'wavegamer5k@gmail.com',
        username: 'wavegamer',
      );

      await _pumpRouter(tester, userFull);

      expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.feed);
      expect(find.text('Não foi possível abrir esta tela.'), findsNothing);
    },
  );

  testWidgets(
    'Unauthenticated user accessing completeProfile redirects directly to login',
    (tester) async {
      await _pumpRouter(tester, null);

      appRouter.go(AppRoutes.completeProfile);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        appRouter.routeInformationProvider.value.uri.path,
        AppRoutes.login,
      );
      expect(
        appRouter.routeInformationProvider.value.uri.queryParameters['from'],
        isNull,
      );
    },
  );

  testWidgets('Tapping back on CompleteProfilePage shows confirmation dialog', (
    tester,
  ) async {
    final userWithoutUsername = testUser(
      id: '6c7ddf73-54a8-41d2-931b-4482f9d7c153',
      displayName: 'Wave LOL',
      email: 'wavegamer5k@gmail.com',
    );

    await _pumpRouter(tester, userWithoutUsername);

    expect(find.text('COMPLETAR PERFIL'), findsOneWidget);

    final backButton = find.byTooltip('Voltar ao login');
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('CANCELAR CADASTRO?'), findsOneWidget);
    expect(find.text('SAIR PARA O LOGIN'), findsOneWidget);
    expect(find.text('CONTINUAR PERFIL'), findsOneWidget);

    await tester.tap(find.text('CONTINUAR PERFIL'));
    await tester.pumpAndSettle();

    expect(find.text('COMPLETAR PERFIL'), findsOneWidget);
    expect(find.text('CANCELAR CADASTRO?'), findsNothing);
  });

  testWidgets(
    'Confirming exit on CompleteProfilePage logs out and navigates to login',
    (tester) async {
      final userWithoutUsername = testUser(
        id: '6c7ddf73-54a8-41d2-931b-4482f9d7c153',
        displayName: 'Wave LOL',
        email: 'wavegamer5k@gmail.com',
      );

      await _pumpRouter(tester, userWithoutUsername);

      // Tap footer action "Sair e escolher outra conta"
      final switchAccountBtn = find.text('Sair e escolher outra conta');
      expect(switchAccountBtn, findsOneWidget);
      await tester.tap(switchAccountBtn);
      await tester.pumpAndSettle();

      expect(find.text('CANCELAR CADASTRO?'), findsOneWidget);

      // Tap "SAIR PARA O LOGIN"
      await tester.tap(find.text('SAIR PARA O LOGIN'));
      await tester.pumpAndSettle();

      // Navigation returns to the login page
      expect(
        appRouter.routeInformationProvider.value.uri.path,
        AppRoutes.login,
      );
    },
  );
}
