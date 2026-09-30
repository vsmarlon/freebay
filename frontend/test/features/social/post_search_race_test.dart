import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/post_search_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

class _DelayedAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final responses = <Completer<ResponseBody>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    final response = Completer<ResponseBody>();
    responses.add(response);
    return response.future;
  }

  @override
  void close({bool force = false}) {}

  void complete(int index, String id) {
    responses[index].complete(
      ResponseBody.fromString(
        jsonEncode({
          'data': [
            {
              'id': id,
              'userId': 'author',
              'createdAt': '2026-09-26T00:00:00Z',
              'user': {'id': 'author'},
            },
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }
}

ProviderContainer _container(_DelayedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
    ..httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [
      socialRepositoryProvider.overrideWithValue(SocialRepository(client: dio)),
    ],
  );
}

Future<void> _waitForRequests(_DelayedAdapter adapter, int count) async {
  for (
    var attempt = 0;
    attempt < 20 && adapter.requests.length < count;
    attempt++
  ) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test('a newer search wins even if an older request finishes last', () async {
    final adapter = _DelayedAdapter();
    final container = _container(adapter);
    addTearDown(container.dispose);
    final search = container.read(postSearchProvider.notifier);

    final first = search.search(query: 'old', refresh: true);
    final second = search.search(
      query: 'new',
      filter: PostSearchFilter.following,
      refresh: true,
    );
    await _waitForRequests(adapter, 2);
    expect(adapter.requests.map((request) => request.queryParameters['q']), [
      'old',
      'new',
    ]);
    expect(adapter.requests.last.queryParameters['filter'], 'following');

    adapter.complete(1, 'new-post');
    await second;
    adapter.complete(0, 'old-post');
    await first;

    final state = container.read(postSearchProvider);
    expect(state.query, 'new');
    expect(state.filter, PostSearchFilter.following);
    expect(state.posts.map((post) => post.id), ['new-post']);
  });

  test('clearing a search invalidates its in-flight response', () async {
    final adapter = _DelayedAdapter();
    final container = _container(adapter);
    addTearDown(container.dispose);
    final search = container.read(postSearchProvider.notifier);

    final pending = search.search(query: 'old', refresh: true);
    await _waitForRequests(adapter, 1);
    search.clear();
    adapter.complete(0, 'old-post');
    await pending;

    final state = container.read(postSearchProvider);
    expect(state.query, '');
    expect(state.posts, isEmpty);
    expect(state.isLoading, isFalse);
  });
}
