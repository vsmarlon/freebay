import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/utils/media_url.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final base = AppConfig.apiBaseUrl;

  group('mediaUrl', () {
    test('prefixes the api base url onto an upload path', () {
      expect(mediaUrl('/uploads/avatar/a.jpg'), '$base/uploads/avatar/a.jpg');
    });

    test('leaves absolute urls untouched', () {
      expect(
        mediaUrl('https://cdn.example.com/a.jpg'),
        'https://cdn.example.com/a.jpg',
      );
    });

    test('leaves legacy data uris untouched', () {
      expect(
        mediaUrl('data:image/png;base64,AAAA'),
        'data:image/png;base64,AAAA',
      );
    });

    test('leaves unrelated paths untouched', () {
      expect(mediaUrl('/products/123'), '/products/123');
    });

    test('absolutizes a private media path', () {
      expect(mediaUrl('/media/chat/a.jpg'), '$base/media/chat/a.jpg');
    });

    test('is idempotent on an already absolute media url', () {
      expect(mediaUrl('$base/media/chat/a.jpg'), '$base/media/chat/a.jpg');
    });
  });

  group('mediaAuthHeaders', () {
    test('returns null for public uploads', () {
      expect(mediaAuthHeaders('$base/uploads/avatar/a.jpg'), isNull);
    });

    test('returns null for a foreign host', () {
      expect(mediaAuthHeaders('https://cdn.example.com/a.jpg'), isNull);
    });

    test(
      'returns null when a foreign host smuggles the api origin in a fragment',
      () {
        expect(
          mediaAuthHeaders('https://evil.example/collect#$base/media/x.jpg'),
          isNull,
        );
      },
    );

    test(
      'returns null when a foreign host smuggles the api origin in a query',
      () {
        expect(
          mediaAuthHeaders('https://evil.example/collect?u=$base/media/x.jpg'),
          isNull,
        );
      },
    );

    test(
      'returns null when the api origin is only a path segment elsewhere',
      () {
        expect(
          mediaAuthHeaders('https://evil.example/$base/media/x.jpg'),
          isNull,
        );
      },
    );

    test(
      'returns null for a lookalike host that merely starts with the api origin',
      () {
        expect(mediaAuthHeaders('$base.evil.example/media/x.jpg'), isNull);
      },
    );

    test('returns null when no token is cached', () {
      expect(mediaAuthHeaders('/media/chat/a.jpg'), isNull);
    });
  });

  group('absolutizeMediaUrls', () {
    test('rewrites upload paths nested in maps and lists', () {
      final payload = {
        'data': {
          'id': 'p1',
          'imageUrl': '/uploads/post/x.png',
          'seller': {'avatarUrl': '/uploads/avatar/y.png'},
          'images': [
            {'url': '/uploads/product/1.jpg'},
            {'url': 'https://cdn.example.com/2.jpg'},
          ],
          'price': 1000,
          'active': true,
          'deletedAt': null,
        },
      };

      final result = absolutizeMediaUrls(payload) as Map<String, dynamic>;
      final data = result['data'] as Map<String, dynamic>;
      final images = data['images'] as List<dynamic>;

      expect(data['imageUrl'], '$base/uploads/post/x.png');
      expect(
        (data['seller'] as Map<String, dynamic>)['avatarUrl'],
        '$base/uploads/avatar/y.png',
      );
      expect(
        (images[0] as Map<String, dynamic>)['url'],
        '$base/uploads/product/1.jpg',
      );
      expect(
        (images[1] as Map<String, dynamic>)['url'],
        'https://cdn.example.com/2.jpg',
      );
      expect(data['price'], 1000);
      expect(data['active'], true);
      expect(data['deletedAt'], isNull);
    });

    test('passes through non-json payloads', () {
      expect(absolutizeMediaUrls(null), isNull);
      expect(absolutizeMediaUrls(42), 42);
    });
  });
}
