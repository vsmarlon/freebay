import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';

class GetPostDetailsUseCase {
  final SocialRepository _repository;

  GetPostDetailsUseCase(this._repository);

  Future<Either<Failure, PostEntity>> call(String postId) async {
    final result = await _repository.getPost(postId);
    return result.fold(
      (_) => const Left(ServerFailure('Erro ao carregar post')),
      Right.new,
    );
  }
}

class GetPostCommentsUseCase {
  final SocialRepository _repository;

  GetPostCommentsUseCase(this._repository);

  Future<Either<Failure, List<CommentEntity>>> call(String postId) async {
    final result = await _repository.getPostComments(postId);
    return result.fold(
      (_) => const Left(ServerFailure('Erro ao carregar comentários')),
      Right.new,
    );
  }
}
