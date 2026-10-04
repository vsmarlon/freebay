import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/entities/uploaded_media.dart';
import 'package:freebay/shared/services/upload_service.dart';

void main() {
  group('UploadService', () {
    test('drops malformed optional BlurHash but keeps the uploaded URL', () {
      final media = UploadedMedia.fromJson({
        'url': '/uploads/post/abc.jpg',
        'blurHash': 'not-a-blurhash',
      });

      expect(media.url, '/uploads/post/abc.jpg');
      expect(media.blurHash, isNull);
    });

    test('parses an optional BlurHash from the upload response envelope', () {
      final media = UploadService.mediaFromResponse({
        'data': {
          'url': '/uploads/post/abc.jpg',
          'blurHash': 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
        },
      });

      expect(media?.url, '/uploads/post/abc.jpg');
      expect(media?.blurHash, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj');
    });

    test('accepts legacy upload responses without a hash', () {
      final media = UploadService.mediaFromResponse({
        'data': {'url': '/uploads/avatar/abc.jpg'},
      });

      expect(media?.url, '/uploads/avatar/abc.jpg');
      expect(media?.blurHash, isNull);
    });

    test('rejects upload responses with no valid URL', () {
      expect(UploadService.mediaFromResponse({'data': {}}), isNull);
      expect(
        UploadService.mediaFromResponse({
          'data': {'url': 123},
        }),
        isNull,
      );
    });
  });
}
