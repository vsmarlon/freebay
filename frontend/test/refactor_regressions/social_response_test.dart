import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';

void main() {
  Map<String, dynamic> post() => {
    'id': 'post-1',
    'userId': 'user-1',
    'content': 'Post',
    'createdAt': '2026-09-20T12:00:00.000Z',
    'user': {'id': 'user-1', 'displayName': 'User'},
  };

  Map<String, dynamic> comment(String id, int likesCount) => {
    'id': id,
    'content': 'Comment',
    'userId': 'user-1',
    'postId': 'post-1',
    'likesCount': likesCount,
    'createdAt': '2026-09-20T12:00:00.000Z',
  };

  SocialRepository repositoryFor(Object data) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object>(
              requestOptions: options,
              data: data,
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return SocialRepository(client: dio);
  }

  test('getPost accepts wrapped and unwrapped response shapes', () async {
    final fixtures = <Map<String, dynamic>>[
      post(),
      {'post': post()},
      {'data': post()},
      {
        'data': {'post': post()},
      },
    ];

    for (final fixture in fixtures) {
      final result = await repositoryFor(fixture).getPost('post-1');

      result.fold(
        (_) => fail('post fixture was rejected: $fixture'),
        (value) => expect(value.id, 'post-1'),
      );
    }
  });

  test('getPost returns a failure for an invalid response shape', () async {
    final result = await repositoryFor({'data': 'invalid'}).getPost('post-1');

    expect(result.isLeft, isTrue);
  });

  test(
    'getPostComments accepts wrapped and unwrapped response shapes',
    () async {
      final fixtures = <Object>[
        [comment('comment-1', 3)],
        {
          'comments': [comment('comment-2', 4)],
        },
        {
          'data': [comment('comment-3', 5)],
        },
        {
          'data': {
            'comments': [comment('comment-4', 6)],
          },
        },
      ];

      for (final fixture in fixtures) {
        final result = await repositoryFor(fixture).getPostComments('post-1');

        result.fold((_) => fail('comment fixture was rejected: $fixture'), (
          value,
        ) {
          expect(value, hasLength(1));
          expect(value.single.id, startsWith('comment-'));
          expect(value.single.likesCount, greaterThan(0));
        });
      }
    },
  );
}
