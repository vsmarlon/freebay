import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/profile/presentation/pages/saved_posts_page.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _Adapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions)> responses = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => responses.removeAt(0)(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _page(String id) => ResponseBody.fromString(
  jsonEncode({
    'success': true,
    'data': {
      'items': [
        {
          'id': id,
          'userId': 'user-1',
          'content': id,
          'createdAt': '2026-09-12T00:00:00.000Z',
          'user': {'id': 'user-1'},
          'isSaved': true,
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

void main() {
  testWidgets('keeps current items when refresh fails', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    adapter.responses.add((_) => _page('post-1'));
    adapter.responses.add((_) => ResponseBody.fromString('', 500));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(
            SocialRepository(client: dio),
          ),
        ],
        child: const MaterialApp(home: SavedPostsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeedPostItem), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(FeedPostItem), findsOneWidget);
  });

  testWidgets('removes an item only after unsave succeeds', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    adapter.responses.add((_) => _page('post-1'));
    adapter.responses.add(
      (_) => ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {'active': false},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(
            SocialRepository(client: dio),
          ),
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'user-1')),
          ),
        ],
        child: const MaterialApp(home: SavedPostsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeedPostItem), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    expect(find.byType(FeedPostItem), findsNothing);
  });
}
