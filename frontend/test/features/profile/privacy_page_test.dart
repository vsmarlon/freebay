import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/presentation/pages/privacy_page.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class _PrivacyRepository extends ProfileRepository {
  int deletionRequests = 0;

  @override
  Future<Either<Failure, DateTime>> requestAccountDeletion({
    required String stepUpToken,
  }) async {
    deletionRequests++;
    return Right(DateTime.parse('2026-10-01T00:00:00.000Z'));
  }
}

class _StepUpAuthRepository extends AuthRepository {
  @override
  Future<Either<Failure, String>> createStepUp({
    required String purpose,
    String? resourceId,
    required Map<String, Object?> proof,
  }) async => const Right('fresh-proof');
}

class _PrivacyAuthController extends AuthController {
  static bool didForceLogout = false;

  @override
  AsyncValue<UserEntity?> build() =>
      const AsyncValue.data(UserEntity(id: 'privacy-test-user'));

  @override
  Future<void> forceLogout() async {
    didForceLogout = true;
    state = const AsyncValue.data(null);
  }
}

void main() {
  testWidgets(
    'deletion requires confirmation and clears the session on success',
    (tester) async {
      final repository = _PrivacyRepository();
      _PrivacyAuthController.didForceLogout = false;
      final router = GoRouter(
        initialLocation: AppRoutes.profilePrivacy,
        routes: [
          GoRoute(
            path: AppRoutes.profilePrivacy,
            builder: (context, state) => PrivacyPage(repository: repository),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) =>
                const Scaffold(body: Text('Logged out')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_PrivacyAuthController.new),
            authRepositoryProvider.overrideWithValue(_StepUpAuthRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('REQUEST ACCOUNT DELETION'));
      await tester.pumpAndSettle();
      expect(repository.deletionRequests, 0);

      await tester.tap(find.text('REQUEST ACCOUNT DELETION').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'current-password');
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      expect(repository.deletionRequests, 1);
      expect(_PrivacyAuthController.didForceLogout, isTrue);
      expect(find.text('Logged out'), findsOneWidget);
    },
  );
}
