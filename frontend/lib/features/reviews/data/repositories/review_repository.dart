import 'package:dio/dio.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/domain/repositories/review_repository.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final Dio client;

  ReviewRepositoryImpl({Dio? client}) : client = client ?? HttpClient.instance;

  @override
  Future<Either<Failure, String>> uploadReviewImage({
    required String orderId,
    required MultipartFile file,
  }) => requestEither(
    () => client.post(
      '/reviews/orders/$orderId/images',
      data: FormData.fromMap({'file': file}),
      options: Options(contentType: 'multipart/form-data'),
    ),
    decoder: (response) {
      final data = response.data;
      final url = data is Map ? (data['url'] ?? data['data']?['url']) : null;
      return Right(url is String ? url : '');
    },
  );

  @override
  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderId,
    required String reviewedId,
    required ReviewType type,
    required int score,
    String? comment,
    List<String> imageIds = const [],
  }) => requestEither(
    () => client.post(
      '/reviews/orders/$orderId',
      data: {
        'reviewedId': reviewedId,
        'type': reviewTypeToApiValue(type),
        'score': score,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (imageIds.isNotEmpty) 'imageIds': imageIds,
      },
    ),
    decoder: (response) => Right(ReviewEntity.fromJson(response.data['data'])),
  );
  @override
  Future<Either<Failure, ReviewListResponse>> getUserReviews(
    String userId, {
    ReviewType? type,
    int limit = defaultReviewPageLimit,
    int offset = 0,
  }) => requestEither(
    () => client.get(
      '/reviews/users/$userId',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'type': type == null ? null : reviewTypeToApiValue(type),
      },
    ),
    decoder: (response) =>
        Right(ReviewListResponse.fromJson(response.data['data'])),
  );

  @override
  Future<Either<Failure, bool>> canReviewOrder(String orderId) => requestEither(
    () => client.get('/reviews/orders/$orderId/can-review'),
    decoder: (response) => Right(response.data['data']['canReview'] == true),
  );
}
