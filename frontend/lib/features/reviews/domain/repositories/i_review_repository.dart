import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IReviewRepository {
  Future<Either<Failure, String>> uploadReviewImage({
    required String orderId,
    required String filePath,
  });

  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderId,
    required String reviewedId,
    required String type,
    required int score,
    String? comment,
    List<String> imagePaths = const [],
  });

  Future<Either<Failure, ReviewListResponse>> getUserReviews(
    String userId, {
    String? type,
    int limit = 10,
    int offset = 0,
  });

  Future<Either<Failure, bool>> canReviewOrder(String orderId);
}
