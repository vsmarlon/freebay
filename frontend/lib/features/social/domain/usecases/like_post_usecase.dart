import 'package:dartz/dartz.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';

class LikePostParams {
  final String postId;
  LikePostParams({required this.postId});
}

class LikePostUsecase implements Usecase<void, LikePostParams> {
  final SocialRepository _repository;

  LikePostUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(LikePostParams params) async {
    return await _repository.likePost(params.postId);
  }
}

class UnlikePostParams {
  final String postId;
  UnlikePostParams({required this.postId});
}

class UnlikePostUsecase implements Usecase<void, UnlikePostParams> {
  final SocialRepository _repository;

  UnlikePostUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(UnlikePostParams params) async {
    return await _repository.unlikePost(params.postId);
  }
}
