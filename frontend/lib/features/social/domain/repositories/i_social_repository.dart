import 'package:dartz/dartz.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class StoriesResponse {
  final List<StoryEntity> stories;
  final bool userHasStory;

  StoriesResponse({required this.stories, required this.userHasStory});
}

abstract class ISocialRepository {
  Future<Either<Failure, List<PostEntity>>> getFeed({
    int limit = 20,
    String? cursor,
    String type = 'explore',
  });
  Future<Either<Failure, PostEntity>> createPost(
      {String? content, String? imagePath, String type = 'REGULAR'});
  Future<Either<Failure, void>> likePost(String postId);
  Future<Either<Failure, void>> unlikePost(String postId);
  Future<Either<Failure, void>> deletePost(String postId);
  Future<Either<Failure, void>> commentPost(String postId, String content,
      {String? parentId});
  Future<Either<Failure, List<CommentEntity>>> getComments(String postId,
      {int limit = 20, String? cursor});
  Future<Either<Failure, void>> likeComment(String commentId);
  Future<Either<Failure, void>> unlikeComment(String commentId);
  Future<Either<Failure, int>> repost(String postId);
  Future<Either<Failure, int>> unrepost(String postId);
  Future<Either<Failure, void>> sharePost(String postId, String? content);

  Future<Either<Failure, StoriesResponse>> getStories();
  Future<Either<Failure, StoryEntity>> createStory(String imagePath);
  Future<Either<Failure, void>> deleteStory(String storyId);
  Future<Either<Failure, void>> viewStory(String storyId);

  Future<Either<Failure, List<UserSearchEntity>>> searchUsers(
      {String? query, int limit = 20, String? cursor});
  Future<Either<Failure, List<UserSearchEntity>>> getSuggestions(
      {int limit = 10});
  Future<Either<Failure, void>> followUser(String userId);
  Future<Either<Failure, void>> unfollowUser(String userId);
  Future<Either<Failure, List<PostEntity>>> searchPosts(
      {String? query, String filter = 'all', int limit = 20, String? cursor});
  Future<Either<Failure, void>> savePost(String postId);
  Future<Either<Failure, void>> unsavePost(String postId);
}
