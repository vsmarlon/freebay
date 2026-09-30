part of '../social_repository.dart';

mixin SocialRepositorySaves {
  Dio get client;

  Future<Either<Failure, T>> stateMutation<T>(
    String path,
    T Function(Map<String, dynamic> data) fromData, {
    bool patch = false,
  });

  Future<Either<Failure, List<PostEntity>>> searchPosts({
    String? query,
    PostSearchFilter filter = PostSearchFilter.all,
    int limit = 20,
    String? cursor,
  }) => requestEither(
    () => client.get(
      '/social/posts/search',
      queryParameters: {
        'limit': limit,
        'filter': filter.wireValue,
        if (query != null && query.isNotEmpty) 'q': query,
        'cursor': ?cursor,
      },
    ),
    decoder: (response) {
      final raw = response.data['data'];
      return Right(_jsonMaps(raw).map(PostEntity.fromJson).toList());
    },
  );

  Future<Either<Failure, CursorPage<PostEntity>>> getPostsByUser(
    String userId, {
    int limit = 20,
    String? cursor,
  }) => requestEither(
    () => client.get(
      '/social/posts/user/$userId',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    ),
    decoder: (response) => Right(
      parseCursorPage<PostEntity>(
        response.data['data'],
        (json) => json.containsKey('post')
            ? UserPostEntry.fromJson(json).toPostEntity()
            : PostEntity.fromJson(json),
      ),
    ),
  );

  Future<Either<Failure, List<UserPostEntry>>> getRepostsByUser(
    String userId, {
    int limit = 20,
    String? cursor,
  }) => requestEither(
    () => client.get(
      '/social/posts/user/$userId/reposts',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    ),
    decoder: (response) {
      final raw = response.data['data'];
      return Right(_jsonMaps(raw).map(UserPostEntry.fromJson).toList());
    },
  );

  Future<Either<Failure, CursorPage<UserPostEntry>>> getProfileTimeline(
    String userId, {
    int limit = 15,
    String? cursor,
    String? kind,
  }) => requestEither(
    () => client.get(
      '/social/posts/user/$userId/timeline',
      queryParameters: {'limit': limit, 'cursor': ?cursor, 'kind': ?kind},
    ),
    decoder: (response) => Right(
      parseCursorPage<UserPostEntry>(
        response.data['data'],
        UserPostEntry.fromJson,
      ),
    ),
  );

  Future<Either<Failure, List<PostEntity>>> getLikedPosts({
    int limit = 20,
    String? cursor,
  }) => requestEither(
    () => client.get(
      '/social/posts/liked',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    ),
    decoder: (response) {
      final raw = response.data['data'];
      return Right(_jsonMaps(raw).map(PostEntity.fromJson).toList());
    },
  );

  Future<Either<Failure, SaveMutationState>> savePost(String postId) =>
      _saveMutation('/social/posts/$postId/save');
  Future<Either<Failure, SaveMutationState>> unsavePost(String postId) =>
      _saveMutation('/social/posts/$postId/unsave', patch: true);
  Future<Either<Failure, SaveMutationState>> _saveMutation(
    String endpoint, {
    bool patch = false,
  }) => stateMutation(
    endpoint,
    (data) => SaveMutationState(active: data['active'] == true),
    patch: patch,
  );

  Future<Either<Failure, CursorPage<PostEntity>>> getSavedPosts({
    int limit = 20,
    String? cursor,
  }) async {
    final result = await requestEither(
      () => client.get(
        '/social/posts/saved',
        queryParameters: {'limit': limit, 'cursor': ?cursor},
      ),
      decoder: (response) => Right(
        parseCursorPage<PostEntity>(response.data['data'], PostEntity.fromJson),
      ),
    );
    return result.fold(
      Left.new,
      (page) => Right(
        CursorPage(
          items: {for (final post in page.items) post.id: post}.values.toList(),
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        ),
      ),
    );
  }
}
