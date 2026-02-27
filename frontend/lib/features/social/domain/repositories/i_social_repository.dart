import 'package:dartz/dartz.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class StoriesResponse {
  final List<StoryEntity> stories;
  final bool userHasStory;

  StoriesResponse({required this.stories, required this.userHasStory});
}

abstract class ISocialRepository {
  Future<Either<Failure, List<PostEntity>>> getFeed(
      {int limit = 20, String? cursor});
  Future<Either<Failure, PostEntity>> createPost(
      {String? content, String? imageUrl, String type = 'REGULAR'});
  Future<Either<Failure, void>> likePost(String postId);
  Future<Either<Failure, void>> unlikePost(String postId);
  Future<Either<Failure, void>> deletePost(String postId);
  Future<Either<Failure, void>> commentPost(String postId, String content,
      {String? parentId});
  Future<Either<Failure, List<CommentEntity>>> getComments(String postId,
      {int limit = 20, String? cursor});
  Future<Either<Failure, void>> sharePost(String postId, String? content);
  
  Future<Either<Failure, StoriesResponse>> getStories();
  Future<Either<Failure, StoryEntity>> createStory(String imageUrl);
  Future<Either<Failure, void>> deleteStory(String storyId);
  Future<Either<Failure, void>> viewStory(String storyId);
}
