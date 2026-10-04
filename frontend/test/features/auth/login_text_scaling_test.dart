import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/presentation/pages/login_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';

void main() {
  for (final scale in [1.5, 2.0]) {
    testWidgets('login form remains scrollable and readable at ${scale}x', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [GoRoute(path: '/login', builder: (_, _) => const LoginPage())],
      );
      FlutterSecureStorage.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => TestAuthController(null)),
          ],
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: MaterialApp.router(
              locale: const Locale('pt', 'BR'),
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppLocalizations.of(
        tester.element(find.byType(LoginPage)),
      );
      expect(find.text(strings.authEnterAccount.toUpperCase()), findsOneWidget);
      expect(find.text(strings.authForgotPassword), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        '${'invalid'.padRight(260, 'x')}@',
      );
      await tester.ensureVisible(
        find.text(strings.authEnterAccount.toUpperCase()),
      );
      await tester.tap(find.text(strings.authEnterAccount.toUpperCase()));
      await tester.pumpAndSettle();

      expect(find.text(strings.authEmailInvalid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
