import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';

class _PostAdapter implements HttpClientAdapter {
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, '/social/posts');
    body = utf8.decode([
      await for (final chunk
          in requestStream ?? const Stream<Uint8List>.empty())
        ...chunk,
    ]);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': 'post-1',
          'userId': 'author',
          'content': 'Para poucos',
          'audience': 'CLOSE_FRIENDS',
          'type': 'REGULAR',
          'createdAt': '2026-09-29T00:00:00.000Z',
          'user': {'id': 'author', 'displayName': 'Alice'},
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('publishes a close-friends post and decodes its audience', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _PostAdapter();
    dio.httpClientAdapter = adapter;

    final result = await SocialRepository(
      client: dio,
    ).createPost(content: 'Para poucos', audience: PostAudience.closeFriends);

    expect(result.rightOrNull?.audience, PostAudience.closeFriends);
    expect(adapter.body, contains('name="audience"\r\n\r\nCLOSE_FRIENDS'));
  });
}
