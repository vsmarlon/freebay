import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freebay/core/components/app_shell.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/pages/profile_page.dart';
import 'package:freebay/features/social/data/entities/user_post_entry.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _SettingsRepository extends SocialRepository {
  @override
  Future<Either<Failure, List<UserSearchEntity>>> getSuggestions({
    int limit = 10,
  }) async => const Right([]);

  @override
  Future<Either<Failure, CursorPage<UserPostEntry>>> getProfileTimeline(
    String userId, {
    int limit = 15,
    String? cursor,
    String? kind,
    CancelToken? cancelToken,
  }) async => const Right(CursorPage.empty());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile settings sheet tracks drag, scrolls, and handles taps', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final user = testUser(id: 'settings-owner');
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        StatefulShellRoute(
          builder: (_, _, shell) => shell,
          navigatorContainerBuilder: (_, shell, children) =>
              AppShell(navigationShell: shell, branches: children),
          branches: [
            for (var index = 0; index < 5; index++)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: index == 4 ? '/profile' : '/branch-$index',
                    builder: (_, _) => index == 4
                        ? const ProfilePage()
                        : Text('BRANCH $index'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => TestAuthController(user)),
          socialRepositoryProvider.overrideWithValue(_SettingsRepository()),
          profileFirstPaintProvider('me').overrideWith(
            (ref) =>
                Stream.value(ProfileFirstPaint(user: user, isStale: false)),
          ),
          profileStatsProvider.overrideWith(
            (ref) async => const UserStatsEntity(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    final originalTop = tester.getRect(sheet).top;

    final drag = await tester.startGesture(
      Offset(tester.getRect(sheet).center.dx, originalTop + 28),
    );
    await tester.pump();
    await drag.moveBy(const Offset(0, 36));
    await tester.pump(const Duration(milliseconds: 16));
    await drag.moveBy(const Offset(0, 36));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.getRect(sheet).top, greaterThan(originalTop));
    await drag.moveBy(const Offset(0, 420));
    await drag.up();
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(router.state.uri.path, '/profile');
    expect(find.text('BRANCH 0'), findsNothing);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final sheetTop = tester.getRect(sheet).top;
    final reverse = await tester.startGesture(
      Offset(tester.getRect(sheet).center.dx, sheetTop + 28),
    );
    await tester.pump();
    await reverse.moveBy(const Offset(0, 24));
    await tester.pump(const Duration(milliseconds: 16));
    await reverse.moveBy(const Offset(0, -24));
    await reverse.up();
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
    expect(router.state.uri.path, '/profile');

    await tester.drag(find.text('Configurações'), const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D'));
    await tester.pump();
    expect(find.text('D'), findsOneWidget);
    expect(router.state.uri.path, '/profile');
  });
}
