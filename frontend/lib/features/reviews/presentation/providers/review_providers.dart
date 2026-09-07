import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/reviews/data/services/review_service.dart';
import 'package:freebay/features/reviews/data/repositories/review_repository.dart';
import 'package:freebay/features/reviews/domain/usecases/can_review_order_usecase.dart';
import 'package:freebay/features/reviews/domain/usecases/create_review_usecase.dart';
import 'package:freebay/features/reviews/domain/usecases/get_user_reviews_usecase.dart';
import 'package:freebay/features/reviews/domain/usecases/upload_review_image_usecase.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(reviewServiceProvider));
});

final uploadReviewImageUsecaseProvider = Provider(
  (ref) => UploadReviewImageUsecase(ref.watch(reviewRepositoryProvider)),
);
final createReviewUsecaseProvider = Provider(
  (ref) => CreateReviewUsecase(ref.watch(reviewRepositoryProvider)),
);
final getUserReviewsUsecaseProvider = Provider(
  (ref) => GetUserReviewsUsecase(ref.watch(reviewRepositoryProvider)),
);
final canReviewOrderUsecaseProvider = Provider(
  (ref) => CanReviewOrderUsecase(ref.watch(reviewRepositoryProvider)),
);
