part of '../social_repository.dart';

mixin SocialRepositoryFeed {
  Dio get client;

  Future<Either<Failure, T>> stateMutation<T>(
    String path,
    T Function(Map<String, dynamic> data) fromData, {
    bool patch = false,
  });

  Future<Either<Failure, FeedPageResult>> getFeed({
    int limit = 20,
    String? cursor,
    int? offset,
    FeedType type = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
  }) => requestEither(
    () => client.get(
      '/social/feed',
      queryParameters: {
        'limit': limit,
        'type': type.wireValue,
        'contentFilter': contentFilter.apiValue,
        'cursor': ?cursor,
        'offset': ?offset,
      },
    ),
    decoder: (response) {
      final map = _jsonMap(response.data['data']);
      final posts = _jsonMaps(map?['posts']).map(PostEntity.fromJson).toList();
      return Right(
        FeedPageResult(
          posts: posts,
          hasMore: map?['hasMore'] == true,
          nextCursor: map?['nextCursor'] as String?,
          nextOffset: map?['nextOffset'] as int?,
        ),
      );
    },
  );

  Future<Either<Failure, PostEntity>> createPost({
    String? content,
    String? imagePath,
    PostType type = PostType.regular,
  }) async {
    try {
      final data = FormData.fromMap({
        'content': ?content,
        'type': type.wireValue,
        if (imagePath != null)
          'image': await ImageUploadService.compressedMultipartFile(
            imagePath,
            filename: 'post.jpg',
          ),
      });
      return requestEither(
        () => client.post(
          '/social/posts',
          data: data,
          options: Options(contentType: 'multipart/form-data'),
        ),
        decoder: (response) =>
            Right(PostEntity.fromJson(response.data['data'])),
      );
    } catch (_) {
      return const Left(ServerFailure('Erro ao processar imagem'));
    }
  }

  Future<Either<Failure, PostMutationState>> likePost(String postId) =>
      _postMutation('/social/posts/$postId/like');
  Future<Either<Failure, PostMutationState>> unlikePost(String postId) =>
      _postMutation('/social/posts/$postId/unlike', patch: true);

  Future<Either<Failure, PostMutationState>> _postMutation(
    String endpoint, {
    bool patch = false,
  }) => stateMutation(
    endpoint,
    (data) => PostMutationState(
      active: data['active'] == true,
      count: data['count'] as int? ?? 0,
    ),
    patch: patch,
  );

  Future<Either<Failure, void>> deletePost(String postId) =>
      requestEither<void>(
        () => client.patch('/social/posts/$postId/delete'),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, PostEntity>> getPost(String postId) => requestEither(
    () => client.get('/social/posts/$postId'),
    decoder: (response) {
      final root = response.data;
      final data = root is Map && root.containsKey('data')
          ? root['data']
          : root;
      final raw = data is Map ? (data['post'] ?? data) : data;
      final map = _jsonMap(raw);
      if (map != null) return Right(PostEntity.fromJson(map));
      throw const FormatException('Invalid post payload');
    },
  );

  Future<Either<Failure, List<CommentEntity>>> getPostComments(String postId) =>
      requestEither(
        () => client.get('/social/posts/$postId/comments'),
        decoder: (response) {
          final root = response.data;
          final data = root is Map && root.containsKey('data')
              ? root['data']
              : root;
          final list = data is List ? data : _jsonMap(data)?['comments'];
          return Right(_jsonMaps(list).map(CommentEntity.fromJson).toList());
        },
      );

  Future<Either<Failure, void>> commentPost(
    String postId,
    String content, {
    String? parentId,
  }) => requestEither<void>(
    () => client.post(
      '/social/posts/$postId/comments',
      data: {
        'content': content,
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      },
    ),
    decoder: (_) => const Right(null),
  );

  Future<Either<Failure, void>> likeComment(String commentId) async {
    final result = await requestEither<void>(
      () => client.post('/social/comments/$commentId/like', data: {'_': true}),
      decoder: (_) => const Right(null),
    );
    return _absorbIdempotentConflict(result);
  }

  Future<Either<Failure, void>> unlikeComment(String commentId) async {
    final result = await requestEither<void>(
      () => client.patch('/social/comments/$commentId/unlike'),
      decoder: (_) => const Right(null),
    );
    return _absorbIdempotentConflict(result);
  }

  Either<Failure, void> _absorbIdempotentConflict(
    Either<Failure, void> result,
  ) => result.fold((failure) {
    final msg = failure.message.toLowerCase();
    if (msg.contains('already') ||
        msg.contains('not liked') ||
        msg.contains('já curtiu') ||
        msg.contains('não curtiu') ||
        msg.contains('já está curtido')) {
      return const Right(null);
    }
    return Left(failure);
  }, Right.new);

  Future<Either<Failure, PostMutationState>> repost(String postId) =>
      _postMutation('/social/posts/$postId/share');
  Future<Either<Failure, PostMutationState>> unrepost(String postId) =>
      _postMutation('/social/posts/$postId/unshare', patch: true);

  Future<Either<Failure, void>> sharePost(String postId, String? content) =>
      requestEither<void>(
        () => client.post(
          '/social/posts/$postId/share',
          data: {'content': content},
        ),
        decoder: (_) => const Right(null),
      );
}
