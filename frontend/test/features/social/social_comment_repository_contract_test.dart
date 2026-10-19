import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';

class _CommentAdapter implements HttpClientAdapter {
  RequestOptions? request;
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    body = utf8.decode([
      await for (final chunk
          in requestStream ?? const Stream<Uint8List>.empty())
        ...chunk,
    ]);
    final payload = options.path.endsWith('/context')
        ? {
            'data': {
              'ancestors': [],
              'focus': _comment('focus'),
              'replies': [],
              'nextReplyCursor': 'reply-next',
              'nextAncestorCursor': 'ancestor-next',
            },
          }
        : {'data': _comment('created')};
    return ResponseBody.fromString(
      jsonEncode(payload),
      options.path.endsWith('/context') ? 200 : 201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _comment(String id) => {
  'id': id,
  'content': 'comment $id',
  'userId': 'user-1',
  'postId': 'post-1',
  'createdAt': '2026-10-14T12:00:00.000Z',
};

void main() {
  test(
    'context paging sends independent opaque cursors and sort to Dio',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _CommentAdapter();
      dio.httpClientAdapter = adapter;

      final result = await SocialRepository(client: dio).getCommentContext(
        'focus',
        replyCursor: 'reply-cursor',
        ancestorCursor: 'ancestor-cursor',
        replySort: 'likes',
      );

      expect(result.rightOrNull?.focus.id, 'focus');
      expect(adapter.request?.queryParameters, {
        'replyLimit': 20,
        'replySort': 'likes',
        'replyCursor': 'reply-cursor',
        'ancestorCursor': 'ancestor-cursor',
      });
    },
  );

  test(
    'comment retry contract carries the request key in header and payload',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _CommentAdapter();
      dio.httpClientAdapter = adapter;

      final result = await SocialRepository(client: dio).createComment(
        'post-1',
        'same payload',
        parentId: 'parent-1',
        clientRequestId: '00000000-0000-4000-8000-000000000001',
      );

      expect(result.rightOrNull?.id, 'created');
      expect(adapter.request?.path, '/social/posts/post-1/comments');
      expect(
        adapter.request?.headers['Idempotency-Key'],
        '00000000-0000-4000-8000-000000000001',
      );
      expect(jsonDecode(adapter.body), {
        'content': 'same payload',
        'clientRequestId': '00000000-0000-4000-8000-000000000001',
        'parentId': 'parent-1',
      });
    },
  );
}
