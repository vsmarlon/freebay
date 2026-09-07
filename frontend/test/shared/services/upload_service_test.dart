import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/services/upload_service.dart';

void main() {
  group('UploadService', () {
    test('returns relative path on success', () {
      expect(
        UploadService.relativePathFromResponse({
          'url': '/uploads/chat/abc.jpg',
        }),
        '/uploads/chat/abc.jpg',
      );
    });

    test('returns null for missing url key', () {
      expect(UploadService.relativePathFromResponse({}), isNull);
    });

    test('returns null for non-string url', () {
      expect(UploadService.relativePathFromResponse({'url': 123}), isNull);
    });
  });
}
