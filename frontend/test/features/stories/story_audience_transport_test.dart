import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/data/repositories/stories_repository.dart';

class _StoryAdapter implements HttpClientAdapter {
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, '/stories');
    expect(options.method, 'POST');
    body = utf8.decode([
      await for (final chunk
          in requestStream ?? const Stream<Uint8List>.empty())
        ...chunk,
    ]);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': 'story-1',
          'userId': 'owner',
          'imageUrl': '/media/story/story.mp4',
          'mediaType': 'VIDEO',
          'audience': 'CLOSE_FRIENDS',
          'createdAt': '2026-09-29T00:00:00.000Z',
          'expiresAt': '2026-09-30T00:00:00.000Z',
          'user': {'id': 'owner', 'displayName': 'Alice'},
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
  test(
    'publishes private video with its audience in the multipart request',
    () async {
      final dir = Directory.systemTemp.createTempSync('freebay_story_');
      final file = File('${dir.path}${Platform.pathSeparator}clip.mp4')
        ..writeAsBytesSync([0, 0, 0, 1]);
      addTearDown(() => dir.deleteSync(recursive: true));
      final client = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _StoryAdapter();
      client.httpClientAdapter = adapter;

      final result = await StoriesRepository(
        client: client,
      ).createStory(file.path, audience: StoryAudience.closeFriends);

      expect(result.rightOrNull?.audience, StoryAudience.closeFriends);
      expect(adapter.body, contains('name="audience"\r\n\r\nCLOSE_FRIENDS'));
    },
  );
}
