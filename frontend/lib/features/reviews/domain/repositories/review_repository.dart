import 'package:dio/dio.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

const defaultReviewPageLimit = 10;

abstract interface class ReviewRepository {
  Future<Either<Failure, String>> uploadReviewImage({
    required String orderId,
    required MultipartFile file,
  });
  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderId,
    required String reviewedId,
    required ReviewType type,
    required int score,
    String? comment,
    List<String> imageIds = const [],
  });
  Future<Either<Failure, ReviewListResponse>> getUserReviews(
    String userId, {
    ReviewType? type,
    int limit = defaultReviewPageLimit,
    int offset = 0,
  });
  Future<Either<Failure, bool>> canReviewOrder(String orderId);
}
