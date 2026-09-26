import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/domain/repositories/review_repository.dart';

class GetUserReviewsParams {
  final String userId;
  final ReviewType? type;
  final int limit;
  final int offset;

  GetUserReviewsParams({
    required this.userId,
    this.type,
    this.limit = defaultReviewPageLimit,
    this.offset = 0,
  });
}

class GetUserReviewsUsecase
    implements Usecase<ReviewListResponse, GetUserReviewsParams> {
  final ReviewRepository _repository;

  GetUserReviewsUsecase(this._repository);

  @override
  UsecaseResponse<Failure, ReviewListResponse> call(
    GetUserReviewsParams params,
  ) {
    return _repository.getUserReviews(
      params.userId,
      type: params.type,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
