import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';

class SocialRepository implements ISocialRepository {
  @override
  Future<Either<Failure, List<PostEntity>>> getFeed({
    int limit = 20,
    String? cursor,
    String type = 'explore',
  }) async {
    try {
      final response = await HttpClient.instance.get(
        '/social/feed',
        queryParameters: {
          'limit': limit,
          'type': type,
          if (cursor != null) 'cursor': cursor,
        },
      );

      if (kDebugMode) {
        debugPrint('[SOCIAL] getFeed status: ${response.statusCode}');
        debugPrint('[SOCIAL] getFeed data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (kDebugMode) {
          debugPrint('[SOCIAL] getFeed inner data: $data');
        }
        final postsData = (data?['posts'] as List?) ?? [];
        final posts = postsData
            .map((json) => PostEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(posts);
      }
      return const Left(ServerFailure('Erro ao carregar feed'));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[SOCIAL] getFeed error: $e');
        debugPrint('[SOCIAL] getFeed stack: $stack');
      }
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> createPost(
      {String? content, String? imagePath, String type = 'REGULAR'}) async {
    try {
      final data = FormData.fromMap({
        if (content != null) 'content': content,
        'type': type,
        if (imagePath != null)
          'image': await ImageUploadService.compressedMultipartFile(
            imagePath,
            filename: 'post.jpg',
          ),
      });

      final response = await HttpClient.instance.post(
        '/social/posts',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
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
          if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
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

      if (kDebugMode) {
        debugPrint('[SOCIAL] getComments status: ${response.statusCode}');
        debugPrint('[SOCIAL] getComments data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final commentsData = (data?['comments'] as List?) ?? [];
        final comments = commentsData
            .map((json) => CommentEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(comments);
      }
      return const Left(ServerFailure('Erro ao carregar comentários'));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[SOCIAL] getComments error: $e');
        debugPrint('[SOCIAL] getComments stack: $stack');
      }
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> likeComment(String commentId) async {
    try {
      await HttpClient.instance
          .post('/social/comments/$commentId/like', data: {'_': true});
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao curtir'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikeComment(String commentId) async {
    try {
      await HttpClient.instance.delete('/social/comments/$commentId/like');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao descurtir'));
    }
  }

  @override
  Future<Either<Failure, int>> repost(String postId) async {
    try {
      final response = await HttpClient.instance.post(
        '/social/posts/$postId/share',
      );
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final sharesCount = data?['sharesCount'] as int? ?? 0;
        return Right(sharesCount);
      }
      return const Right(0);
    } catch (e) {
      return const Left(ServerFailure('Erro ao repostar'));
    }
  }

  @override
  Future<Either<Failure, int>> unrepost(String postId) async {
    try {
      final response = await HttpClient.instance.delete(
        '/social/posts/$postId/share',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final sharesCount = data?['sharesCount'] as int? ?? 0;
        return Right(sharesCount);
      }
      return const Right(0);
    } catch (e) {
      return const Left(ServerFailure('Erro ao remover repost'));
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
  Future<Either<Failure, StoryEntity>> createStory(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'image': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'story.jpg',
        ),
      });

      final response = await HttpClient.instance.post(
        '/social/stories',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
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

  @override
  Future<Either<Failure, List<UserSearchEntity>>> searchUsers(
      {String? query, int limit = 20, String? cursor}) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/search',
        queryParameters: {
          'limit': limit,
          if (query != null && query.isNotEmpty) 'q': query,
          if (cursor != null) 'cursor': cursor,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final users = (data['users'] as List?)
                ?.map((json) =>
                    UserSearchEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        return Right(users);
      }
      return const Left(ServerFailure('Erro ao buscar usuários'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, List<UserSearchEntity>>> getSuggestions(
      {int limit = 10}) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/suggestions',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final users = (data['users'] as List?)
                ?.map((json) =>
                    UserSearchEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        return Right(users);
      }
      return const Left(ServerFailure('Erro ao buscar sugestões'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> followUser(String userId) async {
    try {
      await HttpClient.instance.post('/users/$userId/follow');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao seguir usuário'));
    }
  }

  @override
  Future<Either<Failure, void>> unfollowUser(String userId) async {
    try {
      await HttpClient.instance.delete('/users/$userId/follow');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao deixar de seguir'));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> searchPosts(
      {String? query,
      String filter = 'all',
      int limit = 20,
      String? cursor}) async {
    try {
      final response = await HttpClient.instance.get(
        '/social/posts/search',
        queryParameters: {
          'limit': limit,
          'filter': filter,
          if (query != null && query.isNotEmpty) 'q': query,
          if (cursor != null) 'cursor': cursor,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final posts = (data['posts'] as List?)
                ?.map(
                    (json) => PostEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        return Right(posts);
      }
      return const Left(ServerFailure('Erro ao buscar posts'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, List<PostEntity>>> getPostsByUser(String userId,
      {int limit = 20, String? cursor}) async {
    try {
      final response = await HttpClient.instance.get(
        '/social/posts/user/$userId',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final posts = (data['posts'] as List?)
                ?.map(
                    (json) => PostEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        return Right(posts);
      }
      return const Left(ServerFailure('Erro ao carregar posts'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, List<PostEntity>>> getLikedPosts(
      {int limit = 20, String? cursor}) async {
    try {
      final response = await HttpClient.instance.get(
        '/social/posts/liked',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final posts = (data['posts'] as List?)
                ?.map(
                    (json) => PostEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        return Right(posts);
      }
      return const Left(ServerFailure('Erro ao carregar posts curtidos'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  @override
  Future<Either<Failure, void>> savePost(String postId) async {
    try {
      await HttpClient.instance.post('/social/posts/$postId/save', data: {'_': true});
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao salvar post'));
    }
  }

  @override
  Future<Either<Failure, void>> unsavePost(String postId) async {
    try {
      await HttpClient.instance.delete('/social/posts/$postId/save');
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Erro ao remover post salvo'));
    }
  }

  Future<Either<Failure, List<StoryEntity>>> getUserStories(
      String userId) async {
    try {
      final response =
          await HttpClient.instance.get('/social/stories/user/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final stories = (data['stories'] as List?)
                ?.map((json) =>
                    StoryEntity.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        return Right(stories);
      }
      return const Left(ServerFailure('Erro ao carregar stories'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }
}
