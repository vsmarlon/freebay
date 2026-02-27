import 'package:dartz/dartz.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';

class SharePostParams {
  final String postId;
  final String? content;
  SharePostParams({required this.postId, this.content});
}

class SharePostUsecase implements Usecase<void, SharePostParams> {
  final SocialRepository _repository;

  SharePostUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(SharePostParams params) async {
    return await _repository.sharePost(params.postId, params.content);
  }
}
