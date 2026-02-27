import 'package:freebay/shared/services/http_client.dart';
import '../../../../shared/errors/failures/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/post_entity.dart';
import '../entities/story_entity.dart';
import '../entities/comment_entity.dart';
import '../../domain/repositories/i_social_repository.dart';

class SocialRepository implements ISocialRepository {
  @override
  Future<Either<Failure, List<PostEntity>>> getFeed(
      {int limit = 20, String? cursor}) async {
    try {
      final response = await HttpClient.instance.get(
        '/social/feed',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List;
        final posts = data
            .map((json) => PostEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(posts);
      }
      return const Left(ServerFailure('Erro ao carregar feed'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> createPost(
      {String? content, String? imageUrl, String type = 'REGULAR'}) async {
    try {
      final response = await HttpClient.instance.post(
        '/social/posts',
        data: {
          if (content != null) 'content': content,
          if (imageUrl != null) 'imageUrl': imageUrl,
          'type': type,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final post =
            PostEntity.fromJson(response.data['data'] as Map<String, dynamic>);
        return Right(post);
      }
      return const Left(ServerFailure('Erro ao criar post'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> likePost(String postId) async {
    try {
      await HttpClient.instance
          .post('/social/posts/$postId/like', data: {'_': true});
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao curtir'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId) async {
    try {
      await HttpClient.instance.delete('/social/posts/$postId/like');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao descurtir'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await HttpClient.instance.delete('/social/posts/$postId');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao excluir post'));
    }
  }

  @override
  Future<Either<Failure, void>> commentPost(String postId, String content,
      {String? parentId}) async {
    try {
      await HttpClient.instance.post(
        '/social/posts/$postId/comments',
        data: {
          'content': content,
          if (parentId != null) 'parentId': parentId,
        },
      );
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao comentar'));
    }
  }

  @override
  Future<Either<Failure, List<CommentEntity>>> getComments(String postId,
      {int limit = 20, String? cursor}) async {
    try {
      final response = await HttpClient.instance.get(
        '/social/posts/$postId/comments',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List;
        final comments = data
            .map((json) => CommentEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(comments);
      }
      return const Left(ServerFailure('Erro ao carregar comentários'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> sharePost(
      String postId, String? content) async {
    try {
      await HttpClient.instance.post(
        '/social/posts/$postId/share',
        data: {'content': content},
      );
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao compartilhar'));
    }
  }

  @override
  Future<Either<Failure, StoriesResponse>> getStories() async {
    try {
      final response = await HttpClient.instance.get('/social/stories');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final storiesList = (data['stories'] as List?)
                ?.map((json) =>
                    StoryEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];

        return Right(StoriesResponse(
          stories: storiesList,
          userHasStory: data['userHasStory'] as bool? ?? false,
        ));
      }
      return const Left(ServerFailure('Erro ao carregar stories'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, StoryEntity>> createStory(String imageBase64) async {
    try {
      final response = await HttpClient.instance.post(
        '/social/stories',
        data: {'imageBase64': imageBase64},
      );

      if (response.statusCode == 201 && response.data != null) {
        final story =
            StoryEntity.fromJson(response.data['data'] as Map<String, dynamic>);
        return Right(story);
      }
      return const Left(ServerFailure('Erro ao criar story'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStory(String storyId) async {
    try {
      await HttpClient.instance.delete('/social/stories/$storyId');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao excluir story'));
    }
  }

  @override
  Future<Either<Failure, void>> viewStory(String storyId) async {
    try {
      await HttpClient.instance.post('/social/stories/$storyId/view');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao marcar como visualizado'));
    }
  }
}
