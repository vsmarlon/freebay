import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

class _Adapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions)> responses = [];
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (responses.isEmpty) return ResponseBody.fromString('', 500);
    return responses.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _page(
  List<String> ids, {
  required bool hasMore,
  String? nextCursor,
}) {
  return ResponseBody.fromString(
    jsonEncode({
      'success': true,
      'data': {
        'items': ids
            .map(
              (id) => {
                'id': id,
                'userId': 'user-1',
                'createdAt': '2026-09-12T00:00:00.000Z',
                'user': {'id': 'user-1'},
              },
            )
            .toList(),
        'hasMore': hasMore,
        'nextCursor': nextCursor,
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test(
    'profile timeline sends a server-side kind filter when selected',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _Adapter();
      dio.httpClientAdapter = adapter;
      adapter.responses.add(
        (_) => ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'post': {
                    'id': 'post-1',
                    'userId': 'user-1',
                    'createdAt': '2026-09-12T00:00:00.000Z',
                    'user': {'id': 'user-1'},
                  },
                  'isReposted': false,
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
        ),
      );
      final repository = SocialRepository(client: dio);

      final result = await repository.getProfileTimeline(
        'user-1',
        kind: 'products',
      );

      expect(
        adapter.requests.single.path,
        '/social/posts/user/user-1/timeline',
      );
      expect(adapter.requests.single.queryParameters['kind'], 'products');
      result.fold(
        (failure) => fail(failure.message),
        (page) => expect(page.items.single.post.id, 'post-1'),
      );
    },
  );

  test(
    'deduplicates appended posts and uses server terminal metadata',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _Adapter();
      dio.httpClientAdapter = adapter;
      adapter.responses.add(
        (_) => _page(['post-1'], hasMore: true, nextCursor: 'c1'),
      );
      adapter.responses.add((_) => _page(['post-1', 'post-2'], hasMore: false));
      final container = ProviderContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(
            SocialRepository(client: dio),
          ),
        ],
      );
      addTearDown(container.dispose);

      final provider = userPostsProvider('user-1');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      container.read(provider);
      final notifier = container.read(provider.notifier);
      for (var i = 0; i < 100 && container.read(provider).posts.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await notifier.loadMore();

      final state = container.read(provider);
      expect(state.posts.map((post) => post.id), ['post-1', 'post-2']);
      expect(state.hasMore, isFalse);
      expect(state.cursor, isNull);
    },
  );

  test('retains the failed cursor and retries that same page', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    adapter.responses.add(
      (_) => _page(['post-1'], hasMore: true, nextCursor: 'c1'),
    );
    adapter.responses.add((_) => ResponseBody.fromString('', 500));
    adapter.responses.add((_) => _page(['post-2'], hasMore: false));
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(
          SocialRepository(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = userPostsProvider('user-1');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    container.read(provider);
    final notifier = container.read(provider.notifier);
    for (var i = 0; i < 100 && container.read(provider).posts.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(container.read(provider).cursor, 'c1');
    await notifier.loadMore();
    expect(container.read(provider).cursor, 'c1');
    await notifier.loadMore();

    expect(container.read(provider).posts.map((post) => post.id), [
      'post-1',
      'post-2',
    ]);
    expect(container.read(provider).hasMore, isFalse);
  });
}
