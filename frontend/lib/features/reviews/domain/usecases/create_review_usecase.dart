import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/data/repositories/review_repository.dart';

class CreateReviewParams {
  final String orderId;
  final String reviewedId;
  final String type;
  final int score;
  final String? comment;
  final List<String> imagePaths;

  CreateReviewParams({
    required this.orderId,
    required this.reviewedId,
    required this.type,
    required this.score,
    this.comment,
    this.imagePaths = const [],
  });
}

class CreateReviewUsecase implements Usecase<ReviewEntity, CreateReviewParams> {
  final ReviewRepository _repository;

  CreateReviewUsecase(this._repository);

  @override
  UsecaseResponse<Failure, ReviewEntity> call(CreateReviewParams params) {
    return _repository.createReview(
      orderId: params.orderId,
      reviewedId: params.reviewedId,
      type: params.type,
      score: params.score,
      comment: params.comment,
      imagePaths: params.imagePaths,
    );
  }
}
