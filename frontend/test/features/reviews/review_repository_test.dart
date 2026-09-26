import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/domain/repositories/review_repository.dart';
import 'package:freebay/features/reviews/domain/usecases/create_review_usecase.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _Repository implements ReviewRepository {
  int uploadCalls = 0;
  int createCalls = 0;

  @override
  Future<Either<Failure, String>> uploadReviewImage({
    required String orderId,
    required MultipartFile file,
  }) async {
    uploadCalls++;
    return const Right('image-1');
  }

  @override
  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderId,
    required String reviewedId,
    required ReviewType type,
    required int score,
    String? comment,
    List<String> imageIds = const [],
  }) async {
    createCalls++;
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ReviewListResponse>> getUserReviews(
    String userId, {
    ReviewType? type,
    int limit = 10,
    int offset = 0,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> canReviewOrder(String orderId) =>
      throw UnimplementedError();
}

void main() {
  test('stops before upload and create when image preparation fails', () async {
    final repository = _Repository();
    final result = await CreateReviewUsecase(repository)(
      CreateReviewParams(
        orderId: 'order-1',
        reviewedId: 'seller-1',
        type: ReviewType.sellerReviewingBuyer,
        score: 5,
        imagePaths: const ['missing-image.jpg'],
      ),
    );

    expect(result.isLeft, isTrue);
    expect(repository.uploadCalls, 0);
    expect(repository.createCalls, 0);
  });
}
