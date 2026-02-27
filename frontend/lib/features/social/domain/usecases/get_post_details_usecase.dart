import 'package:freebay/shared/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/shared/services/http_client.dart';

class GetPostDetailsUseCase {
  final HttpClient _httpClient;

  GetPostDetailsUseCase(this._httpClient);

  Future<Either<Failure, PostEntity>> call(String postId) async {
    try {
      final response = await _httpClient.get('/social/posts/$postId');
      final data = response.data['data'] ?? response.data;
      final postJson = data is Map<String, dynamic> ? (data['post'] ?? data) : data;
      return Right(PostEntity.fromJson(postJson as Map<String, dynamic>));
    } catch (e) {
      return const Left(ServerFailure('Erro ao carregar post'));
    }
  }
}

class GetPostCommentsUseCase {
  final HttpClient _httpClient;

  GetPostCommentsUseCase(this._httpClient);

  Future<Either<Failure, List<CommentEntity>>> call(String postId) async {
    try {
      final response = await _httpClient.get('/social/posts/$postId/comments');
      final rawData = response.data['data'] ?? response.data;
      // Backend returns array directly in data, or wrapped in { comments: [...] }
      final List commentsList;
      if (rawData is List) {
        commentsList = rawData;
      } else if (rawData is Map && rawData['comments'] is List) {
        commentsList = rawData['comments'];
      } else {
        return const Right([]);
      }
      return Right(
          commentsList.map((e) => CommentEntity.fromJson(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return const Left(ServerFailure('Erro ao carregar comentários'));
    }
  }
}
