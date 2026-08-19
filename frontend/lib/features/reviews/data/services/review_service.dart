import 'dart:io';
import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';

class ReviewService extends BaseHttpRepository {
  ReviewService({super.client});

  Future<Either<Failure, String>> uploadReviewImage({
    required String orderId,
    required String filePath,
  }) async {
    try {
      final filename = filePath.split(Platform.pathSeparator).last;
      final multipartFile = await ImageUploadService.compressedMultipartFile(
        filePath,
        filename: filename,
      );
      final formData = FormData.fromMap({'file': multipartFile});
      return safePost<String>(
        '/reviews/orders/$orderId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        customMapper: (d) =>
            (d is Map ? (d['url'] ?? d['data']?['url']) : null) as String? ??
            '',
      );
    } catch (_) {
      return const Left(ServerFailure('Erro ao processar imagem.'));
    }
  }

  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderId,
    required String reviewedId,
    required String type,
    required int score,
    String? comment,
    List<String> imagePaths = const [],
  }) async {
    final List<String> imageUrls = [];
    for (final path in imagePaths) {
      final result = await uploadReviewImage(orderId: orderId, filePath: path);
      if (result.isLeft) return Left(result.leftOrNull!);
      imageUrls.add(result.rightOrNull ?? '');
    }

    return safePost<ReviewEntity>(
      '/reviews/orders/$orderId',
      data: {
        'reviewedId': reviewedId,
        'type': type,
        'score': score,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (imageUrls.isNotEmpty) 'imageIds': imageUrls,
      },
      extractKey: 'data',
      fromJson: ReviewEntity.fromJson,
    );
  }

  Future<Either<Failure, ReviewListResponse>> getUserReviews(
    String userId, {
    String? type,
    int limit = 10,
    int offset = 0,
  }) => safeGet<ReviewListResponse>(
    '/reviews/users/$userId',
    queryParameters: {'limit': limit, 'offset': offset, 'type': ?type},
    extractKey: 'data',
    fromJson: ReviewListResponse.fromJson,
  );

  Future<Either<Failure, bool>> canReviewOrder(String orderId) => safeGet<bool>(
    '/reviews/orders/$orderId/can-review',
    extractKey: 'data.canReview',
    customMapper: (d) => d == true,
  );
}
