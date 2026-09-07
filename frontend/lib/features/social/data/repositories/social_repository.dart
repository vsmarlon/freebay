import 'package:dio/dio.dart';
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

  Future<Either<Failure, void>> likePost(String postId) => safeVoid(
    () => client.post('/social/posts/$postId/like', data: {'_': true}),
  );

  Future<Either<Failure, void>> unlikePost(String postId) =>
      safeVoid(() => client.patch('/social/posts/$postId/unlike'));

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
    listKey: 'data.comments',
    fromJson: CommentEntity.fromJson,
  );

  Future<Either<Failure, void>> likeComment(String commentId) => safeVoid(
    () => client.post('/social/comments/$commentId/like', data: {'_': true}),
  );

  Future<Either<Failure, void>> unlikeComment(String commentId) =>
      safeVoid(() => client.patch('/social/comments/$commentId/unlike'));

  Future<Either<Failure, void>> repost(String postId) =>
      safeVoid(() => client.post('/social/posts/$postId/share'));

  Future<Either<Failure, void>> unrepost(String postId) =>
      safeVoid(() => client.patch('/social/posts/$postId/unshare'));

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
          final stories =
              (map['stories'] as List?)
                  ?.whereType<Map>()
                  .map(
                    (j) => StoryEntity.fromJson(Map<String, dynamic>.from(j)),
                  )
                  .toList() ??
              [];
          return StoriesResponse(
            stories: stories,
            userHasStory: map['userHasStory'] as bool? ?? false,
          );
        },
      );

  Future<Either<Failure, StoryEntity>> createStory(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'image': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'story.jpg',
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
    listKey: 'data.posts',
    fromJson: PostEntity.fromJson,
  );

  Future<Either<Failure, List<PostEntity>>> getPostsByUser(
    String userId, {
    int limit = 20,
    String? cursor,
  }) => safeGet<List<PostEntity>>(
    '/social/posts/user/$userId',
    queryParameters: {'limit': limit, 'cursor': ?cursor},
    extractKey: 'data.posts',
    customMapper: (raw) {
      if (raw is! List) return <PostEntity>[];
      return raw.map((json) {
        if (json is Map<String, dynamic> && json.containsKey('post')) {
          return UserPostEntry.fromJson(json).toPostEntity();
        }
        return PostEntity.fromJson(Map<String, dynamic>.from(json as Map));
      }).toList();
    },
  );

  Future<Either<Failure, List<PostEntity>>> getLikedPosts({
    int limit = 20,
    String? cursor,
  }) => safeGetList<PostEntity>(
    '/social/posts/liked',
    queryParameters: {'limit': limit, 'cursor': ?cursor},
    listKey: 'data.posts',
    fromJson: PostEntity.fromJson,
  );

  Future<Either<Failure, void>> savePost(String postId) => safeVoid(
    () => client.post('/social/posts/$postId/save', data: {'_': true}),
  );

  Future<Either<Failure, void>> unsavePost(String postId) =>
      safeVoid(() => client.patch('/social/posts/$postId/unsave'));

  Future<Either<Failure, List<StoryEntity>>> getUserStories(String userId) =>
      safeGetList<StoryEntity>(
        '/stories/user/$userId',
        listKey: 'data.stories',
        fromJson: StoryEntity.fromJson,
      );
}
