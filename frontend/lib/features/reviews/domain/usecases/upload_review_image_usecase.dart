import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/reviews/domain/repositories/i_review_repository.dart';

class UploadReviewImageParams {
  final String orderId;
  final String filePath;

  UploadReviewImageParams({required this.orderId, required this.filePath});
}

class UploadReviewImageUsecase
    implements Usecase<String, UploadReviewImageParams> {
  final IReviewRepository _repository;

  UploadReviewImageUsecase(this._repository);

  @override
  UsecaseResponse<Failure, String> call(UploadReviewImageParams params) {
    return _repository.uploadReviewImage(
        orderId: params.orderId, filePath: params.filePath);
  }
}
