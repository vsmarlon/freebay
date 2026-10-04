import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_shell.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class _TimelineAdapter implements HttpClientAdapter {
  final kinds = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final kind = options.queryParameters['kind'];
    final timelineKind = kind is String ? kind : null;
    kinds.add(timelineKind);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'items': [
            for (var index = 0; index < 18; index++)
              {
                if (timelineKind == 'reposts') ...{
                  'repostId': 'repost-$index',
                  'isReposted': true,
                },
                'post': {
                  'id': '$timelineKind-post-$index',
                  'userId': 'user-1',
                  'content': 'Timeline item $index ${'content ' * 30}',
                  'type': timelineKind == 'products' ? 'PRODUCT' : 'REGULAR',
                  'createdAt': '2026-10-01T00:00:00.000Z',
                  'user': {'id': 'user-1', 'displayName': 'Profile user'},
                  if (timelineKind == 'products')
                    'product': {
                      'id': 'product-$index',
                      'title': 'Listing $index',
                      'description': 'Fixture listing',
                      'price': 100,
                    },
                },
              },
          ],
          'hasMore': false,
          'nextCursor': null,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _flingTabView(
  WidgetTester tester,
  double dx,
  double velocity,
) async {
  final rect = tester.getRect(find.byType(TabBarView));
  await tester.flingFrom(
    Offset(rect.center.dx, rect.top + 100),
    Offset(dx, 0),
    velocity,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('profile tabs page independently without changing shell branch', (
    tester,
  ) async {
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
                        ? const ProfileTabs(
                            user: UserEntity(id: 'user-1'),
                            headerSlivers: [
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 240,
                                  child: Center(child: Text('PROFILE HEADER')),
                                ),
                              ),
                            ],
                          )
                        : Text('BRANCH $index'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _TimelineAdapter();
    dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(
            SocialRepository(client: dio),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PUBLICAÇÕES'), findsOneWidget);
    expect(find.text('REPUBLICAÇÕES'), findsOneWidget);
    expect(find.text('ANÚNCIOS'), findsOneWidget);

    await tester.fling(find.text('PUBLICAÇÕES'), const Offset(-350, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('REPUBLICAÇÕES'), findsOneWidget);
    expect(find.text('BRANCH 0'), findsNothing);
    await tester.fling(find.text('REPUBLICAÇÕES'), const Offset(-350, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('ANÚNCIOS'), findsOneWidget);
    expect(find.text('BRANCH 0'), findsNothing);

    await _flingTabView(tester, -500, 1200);
    expect(find.text('ANÚNCIOS'), findsOneWidget);
    expect(find.text('BRANCH 0'), findsNothing);

    await _flingTabView(tester, 900, 1600);
    await _flingTabView(tester, 900, 1600);
    expect(find.text('PUBLICAÇÕES'), findsOneWidget);

    final pagerRect = tester.getRect(find.byType(TabBarView));
    await tester.dragFrom(
      Offset(pagerRect.left + 2, pagerRect.top + 100),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('PUBLICAÇÕES'), findsOneWidget);
    expect(find.text('BRANCH 0'), findsNothing);

    final initialHeaderY = tester.getCenter(find.text('PROFILE HEADER')).dy;
    await tester.drag(find.text('PROFILE HEADER'), const Offset(0, -120));
    await tester.pumpAndSettle();
    final scrolledHeaderY = tester.getCenter(find.text('PROFILE HEADER')).dy;
    expect(scrolledHeaderY, lessThan(initialHeaderY));
    final outerScroll = find
        .descendant(
          of: find.byType(NestedScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final outerPosition = tester.state<ScrollableState>(outerScroll).position;
    final outerOffset = outerPosition.pixels;

    final timelineOffsets = <String, double>{};
    for (final (index, kind) in ['posts', 'reposts', 'products'].indexed) {
      final scrollable = find
          .descendant(
            of: find.byKey(PageStorageKey('user-1:$kind')),
            matching: find.byType(Scrollable),
          )
          .first;
      final initialOffset = tester
          .state<ScrollableState>(scrollable)
          .position
          .pixels;
      await tester.fling(scrollable, const Offset(0, -700), 1200);
      await tester.pumpAndSettle();
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offset, greaterThan(initialOffset));
      timelineOffsets[kind] = offset;

      if (index < 2) await _flingTabView(tester, -500, 1200);
    }
    expect(outerPosition.pixels, greaterThanOrEqualTo(outerOffset));

    await _flingTabView(tester, 900, 1600);
    await _flingTabView(tester, 900, 1600);
    for (final kind in ['posts', 'reposts', 'products']) {
      final scrollable = find
          .descendant(
            of: find.byKey(PageStorageKey('user-1:$kind')),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        timelineOffsets[kind],
      );
      if (kind != 'products') await _flingTabView(tester, -500, 1200);
    }
    expect(find.text('BRANCH 0'), findsNothing);
    expect(adapter.kinds, containsAll(['posts', 'reposts', 'products']));
  });
}
