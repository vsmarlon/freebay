part of '../social_repository.dart';

mixin SocialRepositoryDiscovery {
  Dio get client;

  Future<Either<Failure, UserSearchPageResult>> searchUsers({
    String? query,
    int limit = 20,
    int offset = 0,
  }) => requestEither(
    () => client.get(
      '/users/search',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    ),
    decoder: (response) {
      final map = _jsonMap(response.data['data']) ?? const <String, dynamic>{};
      final users = _jsonMaps(
        map['users'],
      ).map(UserSearchEntity.fromJson).toList();
      return Right(
        UserSearchPageResult(
          users: users,
          hasMore: map['hasMore'] == true,
          nextOffset: map['nextOffset'] as int?,
        ),
      );
    },
  );

  Future<Either<Failure, List<UserSearchEntity>>> getSuggestions({
    int limit = 10,
  }) => requestEither(
    () => client.get('/users/suggestions', queryParameters: {'limit': limit}),
    decoder: (response) {
      final raw = response.data['data']['users'];
      return Right(_jsonMaps(raw).map(UserSearchEntity.fromJson).toList());
    },
  );

  Future<Either<Failure, void>> followUser(String userId) =>
      requestEither<void>(
        () => client.post('/users/$userId/follow'),
        decoder: (_) => const Right(null),
      );
  Future<Either<Failure, void>> unfollowUser(String userId) =>
      requestEither<void>(
        () => client.patch('/users/$userId/unfollow'),
        decoder: (_) => const Right(null),
      );
}
