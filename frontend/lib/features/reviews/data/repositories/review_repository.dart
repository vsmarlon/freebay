import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/data/services/review_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class ReviewRepository {
  final ReviewService _service;

  ReviewRepository(this._service);

  Future<Either<Failure, String>> uploadReviewImage({
    required String orderId,
    required String filePath,
  }) {
    return _service.uploadReviewImage(orderId: orderId, filePath: filePath);
  }

  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderId,
    required String reviewedId,
    required String type,
    required int score,
    String? comment,
    List<String> imagePaths = const [],
  }) {
    return _service.createReview(
      orderId: orderId,
      reviewedId: reviewedId,
      type: type,
      score: score,
      comment: comment,
      imagePaths: imagePaths,
    );
  }

  Future<Either<Failure, ReviewListResponse>> getUserReviews(
    String userId, {
    String? type,
    int limit = 10,
    int offset = 0,
  }) {
    return _service.getUserReviews(
      userId,
      type: type,
      limit: limit,
      offset: offset,
    );
  }

  Future<Either<Failure, bool>> canReviewOrder(String orderId) {
    return _service.canReviewOrder(orderId);
  }
}
