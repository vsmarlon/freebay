// Owner-approved real-device journey (2026-11-09): the only Flutter integration
// suite in the repo, gated in CI (`mobile-ui`) and never a local `flutter test`
// gate. It proves the app itself can log in, perform a real business write and
// read the persisted value back from Nest/PostgreSQL after a fresh start.
//
// Runs on a debug build against the guarded CI database:
//   adb reverse tcp:3000 tcp:43187   (app localhost -> CI backend)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/main.dart' as app;
import 'package:freebay/shared/config/app_config.dart';

// PT labels: the journey pins `locale_preference` so the finders are deterministic.
const _emailLabel = 'E-mail ou @usuário';
const _passwordLabel = 'Senha';
const _loginButton = 'ENTRAR NA SUA CONTA';
const _nameLabel = 'Nome';
const _saveButton = 'Salvar';
const _notNowButton = 'Agora não';
const _finishButton = 'Concluir';

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Timed pumps instead of `pumpAndSettle`: the app keeps shimmer skeletons and
/// spinners alive while real network calls are in flight, so settling would hang.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  fail('Timed out waiting for the expected app state');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // Long forms can sit below the fold on small viewports; not every page scrolls.
  try {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 100));
  } catch (_) {
    // No Scrollable ancestor: the control is already laid out, tap it directly.
  }
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

/// Registers a throwaway `ci_*` account through the real API, exactly like the
/// web real-backend journey does, so the UI part of the journey starts from a
/// known credential instead of driving the whole registration form.
Future<bool> _registerDisposableAccount({
  required String email,
  required String username,
  required String password,
  required String displayName,
}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'displayName': displayName,
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 201) return false;
    return (jsonDecode(body) as Map<String, dynamic>)['success'] == true;
  } finally {
    client.close(force: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Deterministic PT labels and no onboarding gate; secure storage stays real so
  // the second app start can restore the session token.
  SharedPreferences.setMockInitialValues({
    'locale_preference': 'pt_BR',
    'has_seen_onboarding': true,
    'private_media_cache_cleaned_v1': true,
  });

  testWidgets(
    'real backend login updates the profile and the value survives a fresh app start',
    (tester) async {
      final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final email = 'ci-$suffix@example.invalid';
      final username = 'ci_$suffix';
      final password = 'CI-only-$suffix-9a';
      final originalName = 'CI User $suffix';
      final updatedName = 'CI Saved $suffix';

      expect(
        await _registerDisposableAccount(
          email: email,
          username: username,
          password: password,
          displayName: originalName,
        ),
        isTrue,
        reason: 'the real backend must accept the disposable account',
      );

      app.main();
      await _pumpUntil(
        tester,
        () => find
            .widgetWithText(AppTextField, _emailLabel)
            .evaluate()
            .isNotEmpty,
      );

      await tester.enterText(
        find.widgetWithText(AppTextField, _emailLabel),
        email,
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, _passwordLabel),
        password,
      );
      await _tap(tester, find.widgetWithText(AppButton, _loginButton));

      // A brand-new account is routed to the post-login setup before the feed.
      await _pumpUntil(
        tester,
        () =>
            appRouter.routeInformationProvider.value.uri.path ==
            AppRoutes.welcome,
      );
      for (var step = 0; step < 2; step++) {
        await _tap(tester, find.widgetWithText(AppButton, _notNowButton));
        await _pumpFor(tester, const Duration(milliseconds: 400));
      }
      await _tap(tester, find.widgetWithText(AppButton, _finishButton));
      await _pumpUntil(
        tester,
        () =>
            appRouter.routeInformationProvider.value.uri.path == AppRoutes.feed,
      );

      appRouter.go(AppRoutes.profileEdit);
      await _pumpUntil(
        tester,
        () =>
            find.widgetWithText(AppTextField, _nameLabel).evaluate().isNotEmpty,
      );
      // The save action stays disabled until GET /users/me has loaded the profile.
      await _pumpUntil(
        tester,
        () =>
            tester
                .widget<AppButton>(find.widgetWithText(AppButton, _saveButton))
                .onPressed !=
            null,
      );

      await tester.enterText(
        find.widgetWithText(AppTextField, _nameLabel),
        updatedName,
      );
      await _tap(tester, find.widgetWithText(AppButton, _saveButton));
      await _pumpUntil(
        tester,
        () =>
            appRouter.routeInformationProvider.value.uri.path !=
            AppRoutes.profileEdit,
      );

      // Fresh app start: the session comes back from secure storage and the profile
      // is re-read from the real backend, so the updated name must still be there.
      // The router is a process-wide singleton, so reset it to the splash entry
      // before starting the app again; otherwise this would only assert the page
      // left open by the first start.
      appRouter.go(AppRoutes.splash);
      app.main();
      await _pumpFor(tester, const Duration(seconds: 2));
      await _pumpUntil(
        tester,
        () => !{
          AppRoutes.splash,
          AppRoutes.login,
        }.contains(appRouter.routeInformationProvider.value.uri.path),
        timeout: const Duration(seconds: 60),
      );
      appRouter.go(AppRoutes.profile);
      await _pumpUntil(
        tester,
        () => find.text(updatedName).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 60),
      );
      expect(find.text(updatedName), findsWidgets);
    },
  );
}
