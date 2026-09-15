import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/profile/data/services/follow_service.dart';

class _MockFollowAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> handlers = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    final handler = handlers[key];
    if (handler != null) {
      return handler(options);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'error': {'message': 'Not found'},
      }),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('FollowService', () {
    late Dio dio;
    late _MockFollowAdapter adapter;
    late FollowService followService;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      adapter = _MockFollowAdapter();
      dio.httpClientAdapter = adapter;
      followService = FollowService(client: dio);
    });

    test('follow returns success when 200 returned', () async {
      adapter.handlers['POST /users/u1/follow'] = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {
              'following': true,
              'followersCount': 100,
              'followingCount': 50,
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final result = await followService.follow('u1');
      expect(result.isRight, isTrue);
      result.fold((_) => fail('Follow request failed'), (res) {
        expect(res.following, isTrue);
        expect(res.followersCount, equals(100));
        expect(res.followingCount, equals(50));
      });
    });

    test(
      'follow absorbs 400 "Already following" and returns Right(FollowResponse)',
      () async {
        // POST returns 400 Already following
        adapter.handlers['POST /users/u1/follow'] = (options) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': false,
              'error': {'code': 'BAD_REQUEST', 'message': 'Already following'},
            }),
            400,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        // Status check fallback returns current status
        adapter.handlers['GET /users/u1/is-following'] = (options) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'isFollowing': true,
                'followersCount': 105,
                'followingCount': 50,
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final result = await followService.follow('u1');
        expect(result.isRight, isTrue);
        result.fold((_) => fail('Already-following fallback failed'), (res) {
          expect(res.following, isTrue);
          expect(res.followersCount, equals(105));
        });
      },
    );

    test(
      'unfollow absorbs 400 "Not following" and returns Right(FollowResponse)',
      () async {
        // PATCH returns 400 Not following
        adapter.handlers['PATCH /users/u1/unfollow'] = (options) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': false,
              'error': {'code': 'BAD_REQUEST', 'message': 'Not following'},
            }),
            400,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        // Status check fallback returns current status
        adapter.handlers['GET /users/u1/is-following'] = (options) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'isFollowing': false,
                'followersCount': 104,
                'followingCount': 50,
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final result = await followService.unfollow('u1');
        expect(result.isRight, isTrue);
        result.fold((_) => fail('Not-following fallback failed'), (res) {
          expect(res.following, isFalse);
          expect(res.followersCount, equals(104));
        });
      },
    );
  });
}
