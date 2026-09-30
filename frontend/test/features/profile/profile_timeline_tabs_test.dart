import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_shell.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

class _TimelineAdapter implements HttpClientAdapter {
  final kinds = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final kind = options.queryParameters['kind'];
    kinds.add(kind is String ? kind : null);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'items': [], 'hasMore': false, 'nextCursor': null},
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
                                  height: 500,
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
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PUBLICAÇÕES'), findsOneWidget);
    expect(find.text('REPOSTS'), findsOneWidget);
    expect(find.text('ANÚNCIOS'), findsOneWidget);

    await tester.fling(find.text('PUBLICAÇÕES'), const Offset(-350, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('REPOSTS'), findsOneWidget);
    expect(find.text('BRANCH 0'), findsNothing);
    await tester.fling(find.text('REPOSTS'), const Offset(-350, 0), 1000);
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
    await tester.drag(find.text('PROFILE HEADER'), const Offset(0, -300));
    await tester.pumpAndSettle();
    final scrolledHeaderY = tester.getCenter(find.text('PROFILE HEADER')).dy;
    expect(scrolledHeaderY, lessThan(initialHeaderY));

    await _flingTabView(tester, -350, 1000);
    expect(tester.getCenter(find.text('PROFILE HEADER')).dy, scrolledHeaderY);
    await _flingTabView(tester, -350, 1000);
    expect(tester.getCenter(find.text('PROFILE HEADER')).dy, scrolledHeaderY);
    expect(find.text('BRANCH 0'), findsNothing);
    expect(adapter.kinds, containsAll(['posts', 'reposts', 'products']));
  });
}
