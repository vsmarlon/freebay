import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    body = latin1.decode([
      await for (final chunk
          in requestStream ?? const Stream<Uint8List>.empty())
        ...chunk,
    ]);
    return ResponseBody.fromString(
      jsonEncode({'data': _post()}),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _post() => {
  'id': 'quote-1',
  'userId': 'user-1',
  'content': 'quoted',
  'createdAt': '2026-10-15T12:00:00.000Z',
  'user': {'id': 'user-1'},
  'isQuote': true,
  'quoteSource': null,
};

void main() {
  test('quote sends exactly one source and idempotency key', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;

    final selectedUsers = [
      const UserSearchEntity(id: 'user-2', displayName: 'Second'),
      const UserSearchEntity(id: 'user-1', displayName: 'First'),
      const UserSearchEntity(id: 'user-2', displayName: 'Second'),
    ];
    final result = await SocialRepository(client: dio).createQuote(
      content: 'my commentary',
      sourceId: 'comment-1',
      sourceIsComment: true,
      clientRequestId: '00000000-0000-4000-8000-000000000001',
      mentionIds: selectedUsers.map((user) => user.id).toList(),
    );

    expect(result.rightOrNull?.id, 'quote-1');
    expect(adapter.request?.path, '/social/quotes');
    expect(
      adapter.request?.headers['Idempotency-Key'],
      '00000000-0000-4000-8000-000000000001',
    );
    expect(jsonDecode(adapter.body), {
      'content': 'my commentary',
      'sourceCommentId': 'comment-1',
      'mentionIds': ['user-1', 'user-2'],
      'clientRequestId': '00000000-0000-4000-8000-000000000001',
    });
    expect(adapter.body, isNot(contains('imageUrl')));
    expect(adapter.body, isNot(contains('postId')));
  });

  test('image quote encodes one mention as an array multipart field', () async {
    final directory = await Directory.systemTemp.createTemp('quote-upload-');
    final imagePath = '${directory.path}${Platform.pathSeparator}source.png';
    await File(
      imagePath,
    ).writeAsBytes(img.encodePng(img.Image(width: 2, height: 2)));
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;

    try {
      final result = await SocialRepository(client: dio).createQuote(
        content: 'my commentary',
        sourceId: 'post-1',
        sourceIsComment: false,
        clientRequestId: '00000000-0000-4000-8000-000000000002',
        mentionIds: ['user-1'],
        imagePath: imagePath,
      );

      expect(result.rightOrNull?.id, 'quote-1');
      expect(
        adapter.request?.headers['Idempotency-Key'],
        '00000000-0000-4000-8000-000000000002',
      );
      expect(adapter.body, contains('name="mentionIds[]"'));
      expect(adapter.body, isNot(contains('name="mentionIds"')));
      expect(adapter.body, contains('user-1'));
      expect(adapter.body, contains('name="sourcePostId"'));
      expect(adapter.body, contains('name="image"; filename="quote.jpg"'));
      expect(adapter.body, contains('content-type: image/jpeg'));
      expect(adapter.body, isNot(contains('imageUrl')));
    } finally {
      await directory.delete(recursive: true);
      dio.close();
    }
  });
}
