import 'package:dartz/dartz.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';

class CommentPostParams {
  final String postId;
  final String content;
  final String? parentId;
  CommentPostParams(
      {required this.postId, required this.content, this.parentId});
}

class CommentPostUsecase implements Usecase<void, CommentPostParams> {
  final SocialRepository _repository;

  CommentPostUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(CommentPostParams params) async {
    return await _repository.commentPost(params.postId, params.content,
        parentId: params.parentId);
  }
}
