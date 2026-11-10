import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/reviews/data/repositories/review_repository.dart';
import 'package:freebay/features/reviews/domain/repositories/review_repository.dart';
import 'package:freebay/features/reviews/domain/usecases/can_review_order_usecase.dart';
import 'package:freebay/features/reviews/domain/usecases/create_review_usecase.dart';
import 'package:freebay/features/reviews/domain/usecases/get_user_reviews_usecase.dart';
import 'package:freebay/features/reviews/domain/usecases/upload_review_image_usecase.dart';
import 'package:freebay/shared/services/http_client.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepositoryImpl(client: HttpClient.instance),
);

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
