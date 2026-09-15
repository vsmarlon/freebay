import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/entities/user_post_entry.dart';
import 'package:freebay/features/social/data/entities/feed_page_result.dart';
import 'package:freebay/features/social/data/entities/user_search_page_result.dart';
import 'package:freebay/shared/models/cursor_page.dart';

class PostMutationState {
  final bool active;
  final int count;
  const PostMutationState({required this.active, required this.count});
}

class SaveMutationState {
  final bool active;
  const SaveMutationState({required this.active});
}

class SocialRepository extends BaseHttpRepository {
  SocialRepository({super.client});

  Future<Either<Failure, FeedPageResult>> getFeed({
    int limit = 20,
    String? cursor,
    int? offset,
    String type = 'explore',
    String contentFilter = 'all',
  }) {
    return safeGet<FeedPageResult>(
      '/social/feed',
      queryParameters: {
        'limit': limit,
        'type': type,
        'contentFilter': contentFilter,
        'cursor': ?cursor,
        'offset': ?offset,
      },
      extractKey: 'data',
      customMapper: (data) {
        final map = data as Map<String, dynamic>?;
        final postsData = (map?['posts'] as List?) ?? [];
        final posts = postsData
            .whereType<Map>()
            .map((json) => PostEntity.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        return FeedPageResult(
          posts: posts,
          hasMore: map?['hasMore'] == true,
          nextCursor: map?['nextCursor'] as String?,
          nextOffset: map?['nextOffset'] as int?,
        );
      },
    );
  }

  Future<Either<Failure, PostEntity>> createPost({
    String? content,
    String? imagePath,
    String type = 'REGULAR',
  }) async {
    try {
      final data = FormData.fromMap({
        'content': ?content,
        'type': type,
        if (imagePath != null)
          'image': await ImageUploadService.compressedMultipartFile(
            imagePath,
            filename: 'post.jpg',
          ),
      });
      return safePost<PostEntity>(
        '/social/posts',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
        extractKey: 'data',
        fromJson: PostEntity.fromJson,
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
    String path, {
    bool patch = false,
  }) => safeCall<PostMutationState>(
    () => client.request(
      path,
      options: Options(method: patch ? 'PATCH' : 'POST'),
    ),
    onSuccess: (response) {
      final data = response.data['data'] as Map;
      return Right(
        PostMutationState(
          active: data['active'] == true,
          count: data['count'] as int? ?? 0,
        ),
      );
    },
  );

  Future<Either<Failure, void>> deletePost(String postId) =>
      safeVoid(() => client.patch('/social/posts/$postId/delete'));

  Future<Either<Failure, void>> commentPost(
    String postId,
    String content, {
    String? parentId,
  }) => safeVoid(
    () => client.post(
      '/social/posts/$postId/comments',
      data: {
        'content': content,
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      },
    ),
  );

  Future<Either<Failure, List<CommentEntity>>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) => safeGetList<CommentEntity>(
    '/social/posts/$postId/comments',
    queryParameters: {'limit': limit, 'cursor': ?cursor},
    listKey: 'data',
    fromJson: CommentEntity.fromJson,
  );

  Future<Either<Failure, void>> likeComment(String commentId) async {
    final res = await safeVoid(
      () => client.post('/social/comments/$commentId/like', data: {'_': true}),
    );
    return _absorbIdempotentConflict(res);
  }

  Future<Either<Failure, void>> unlikeComment(String commentId) async {
    final res = await safeVoid(
      () => client.patch('/social/comments/$commentId/unlike'),
    );
    return _absorbIdempotentConflict(res);
  }

  Either<Failure, void> _absorbIdempotentConflict(
    Either<Failure, void> result,
  ) {
    return result.fold((failure) {
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
  }

  Future<Either<Failure, PostMutationState>> repost(String postId) =>
      _postMutation('/social/posts/$postId/share');

  Future<Either<Failure, PostMutationState>> unrepost(String postId) =>
      _postMutation('/social/posts/$postId/unshare', patch: true);

  Future<Either<Failure, void>> sharePost(String postId, String? content) =>
      safeVoid(
        () => client.post(
          '/social/posts/$postId/share',
          data: {'content': content},
        ),
      );

  Future<Either<Failure, StoriesResponse>> getStories() =>
      safeGet<StoriesResponse>(
        '/stories',
        extractKey: 'data',
        customMapper: (data) {
          final map = data as Map<String, dynamic>;
          final groups =
              (map['stories'] as List?)?.whereType<Map>().map((json) {
                final group = Map<String, dynamic>.from(json);
                final user = StoryUserEntity.fromJson(
                  Map<String, dynamic>.from(group['user'] as Map),
                );
                final items =
                    (group['stories'] as List?)?.whereType<Map>().map((item) {
                      final value = Map<String, dynamic>.from(item);
                      return StoryGroupItem(
                        id: value['id'] as String,
                        imageUrl: value['imageUrl'] as String,
                        createdAt: DateTime.parse(value['createdAt'] as String),
                        expiresAt: DateTime.parse(value['expiresAt'] as String),
                        mediaType: value['mediaType'] as String? ?? 'IMAGE',
                        caption: value['caption'] as String?,
                        textBlocks: value['textBlocks'] is List
                            ? (value['textBlocks'] as List)
                                  .whereType<Map>()
                                  .map(
                                    (item) => StoryTextBlockEntity.fromJson(
                                      Map<String, dynamic>.from(item),
                                    ),
                                  )
                                  .toList()
                            : null,
                      );
                    }).toList() ??
                    [];
                return StoryGroupEntity(user: user, stories: items);
              }).toList() ??
              [];
          return StoriesResponse(
            groups: groups,
            userHasStory: map['userHasStory'] as bool? ?? false,
          );
        },
      );

  Future<Either<Failure, StoryEntity>> createStory(
    String imagePath, {
    String? caption,
    List<StoryTextBlockEntity> textBlocks = const [],
  }) async {
    try {
      final isVideo = [
        '.mp4',
        '.mov',
        '.webm',
      ].any(imagePath.toLowerCase().endsWith);
      final data = FormData.fromMap({
        'image': isVideo
            ? await MultipartFile.fromFile(
                imagePath,
                filename: 'story${path.extension(imagePath).toLowerCase()}',
                contentType: DioMediaType.parse(_videoMime(imagePath)),
              )
            : await ImageUploadService.compressedMultipartFile(
                imagePath,
                filename: 'story.jpg',
              ),
        if (caption != null && caption.trim().isNotEmpty)
          'caption': caption.trim(),
        'textBlocks': jsonEncode(
          textBlocks.map((block) => block.toJson()).toList(),
        ),
      });
      return safePost<StoryEntity>(
        '/stories',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
        extractKey: 'data',
        fromJson: StoryEntity.fromJson,
      );
    } catch (_) {
      return const Left(ServerFailure('Erro ao processar imagem'));
    }
  }

  String _videoMime(String imagePath) {
    switch (path.extension(imagePath).toLowerCase()) {
      case '.mov':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  Future<Either<Failure, void>> deleteStory(String storyId) =>
      safeVoid(() => client.patch('/stories/$storyId/delete'));

  Future<Either<Failure, void>> viewStory(String storyId) =>
      safeVoid(() => client.post('/stories/$storyId/view'));

  Future<Either<Failure, UserSearchPageResult>> searchUsers({
    String? query,
    int limit = 20,
    int offset = 0,
  }) => safeGet<UserSearchPageResult>(
    '/users/search',
    queryParameters: {
      'limit': limit,
      'offset': offset,
      if (query != null && query.isNotEmpty) 'q': query,
    },
    extractKey: 'data',
    customMapper: (data) {
      final map = data as Map<String, dynamic>;
      final users =
          (map['users'] as List?)
              ?.whereType<Map>()
              .map(
                (j) => UserSearchEntity.fromJson(Map<String, dynamic>.from(j)),
              )
              .toList() ??
          [];
      return UserSearchPageResult(
        users: users,
        hasMore: map['hasMore'] == true,
        nextOffset: map['nextOffset'] as int?,
      );
    },
  );

  Future<Either<Failure, List<UserSearchEntity>>> getSuggestions({
    int limit = 10,
  }) => safeGetList<UserSearchEntity>(
    '/users/suggestions',
    queryParameters: {'limit': limit},
    listKey: 'data.users',
    fromJson: UserSearchEntity.fromJson,
  );

  Future<Either<Failure, void>> followUser(String userId) =>
      safeVoid(() => client.post('/users/$userId/follow'));

  Future<Either<Failure, void>> unfollowUser(String userId) =>
      safeVoid(() => client.patch('/users/$userId/unfollow'));

  Future<Either<Failure, List<PostEntity>>> searchPosts({
    String? query,
    String filter = 'all',
    int limit = 20,
    String? cursor,
  }) => safeGetList<PostEntity>(
    '/social/posts/search',
    queryParameters: {
      'limit': limit,
      'filter': filter,
      if (query != null && query.isNotEmpty) 'q': query,
      'cursor': ?cursor,
    },
    listKey: 'data',
    fromJson: PostEntity.fromJson,
  );

  Future<Either<Failure, CursorPage<PostEntity>>> getPostsByUser(
    String userId, {
    int limit = 20,
    String? cursor,
  }) => safePage<PostEntity>(
    '/social/posts/user/$userId',
    (json) => json.containsKey('post')
        ? UserPostEntry.fromJson(json).toPostEntity()
        : PostEntity.fromJson(json),
    limit: limit,
    cursor: cursor,
  );

  Future<Either<Failure, List<UserPostEntry>>> getRepostsByUser(
    String userId, {
    int limit = 20,
    String? cursor,
  }) => safeGet<List<UserPostEntry>>(
    '/social/posts/user/$userId/reposts',
    queryParameters: {'limit': limit, 'cursor': ?cursor},
    extractKey: 'data',
    customMapper: (raw) {
      if (raw is! List) return <UserPostEntry>[];
      return raw
          .whereType<Map>()
          .map(
            (json) => UserPostEntry.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    },
  );

  Future<Either<Failure, List<PostEntity>>> getLikedPosts({
    int limit = 20,
    String? cursor,
  }) => safeGetList<PostEntity>(
    '/social/posts/liked',
    queryParameters: {'limit': limit, 'cursor': ?cursor},
    listKey: 'data',
    fromJson: PostEntity.fromJson,
  );

  Future<Either<Failure, SaveMutationState>> savePost(String postId) =>
      _saveMutation('/social/posts/$postId/save');

  Future<Either<Failure, SaveMutationState>> unsavePost(String postId) =>
      _saveMutation('/social/posts/$postId/unsave', patch: true);

  Future<Either<Failure, SaveMutationState>> _saveMutation(
    String path, {
    bool patch = false,
  }) => safeCall<SaveMutationState>(
    () => client.request(
      path,
      options: Options(method: patch ? 'PATCH' : 'POST'),
    ),
    onSuccess: (response) => Right(
      SaveMutationState(
        active: (response.data['data'] as Map)['active'] == true,
      ),
    ),
  );

  Future<Either<Failure, CursorPage<PostEntity>>> getSavedPosts({
    int limit = 20,
    String? cursor,
  }) async {
    final result = await safePage<PostEntity>(
      '/social/posts/saved',
      PostEntity.fromJson,
      limit: limit,
      cursor: cursor,
      itemsKey: 'posts',
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

  Future<Either<Failure, List<StoryEntity>>> getUserStories(String userId) =>
      safeGetList<StoryEntity>(
        '/stories/user/$userId',
        listKey: 'data',
        fromJson: StoryEntity.fromJson,
      );
}
