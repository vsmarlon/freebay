import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

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

ResponseBody _mutation({required bool active}) => ResponseBody.fromString(
  jsonEncode({
    'success': true,
    'data': {'active': active},
  }),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test('restores a failed unsave and retries successfully', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;
    adapter.responses.add((_) => ResponseBody.fromString('', 500));
    adapter.responses.add((_) => _mutation(active: false));
    final container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(
          SocialRepository(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(savesProvider.notifier);

    expect(await notifier.toggleSave('post-1', initialIsSaved: true), isFalse);
    expect(container.read(savesProvider).getSavedOverride('post-1'), isTrue);
    expect(await notifier.toggleSave('post-1', initialIsSaved: true), isTrue);
    expect(container.read(savesProvider).getSavedOverride('post-1'), isFalse);
  });
}
