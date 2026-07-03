import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';

class ReviewService {
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData != null && responseData is Map) {
        final errorObj = responseData['error'];
        if (errorObj != null && errorObj is Map) {
          final message = errorObj['message'];
          if (message != null) return message.toString();
        }
      }
    }
    return 'Erro ao conectar com o servidor.';
  }

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

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await HttpClient.instance.post(
        '/reviews/orders/$orderId/images',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        final url = response.data['data']?['url'] as String? ??
            response.data['url'] as String?;
        if (url != null) {
          return Right(url);
        }
        return Left(ServerFailure('Erro ao obter URL da imagem.'));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
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
    try {
      final List<String> imageUrls = [];
      for (final path in imagePaths) {
        final result = await uploadReviewImage(
          orderId: orderId,
          filePath: path,
        );
        if (result.isLeft()) {
          return Left((result as Left<Failure, String>).value);
        }
        imageUrls.add(result.getOrElse(() => ''));
      }

      final response = await HttpClient.instance.post(
        '/reviews/orders/$orderId',
        data: {
          'reviewedId': reviewedId,
          'type': type,
          'score': score,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (imageUrls.isNotEmpty) 'imageIds': imageUrls,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return Right(ReviewEntity.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, ReviewListResponse>> getUserReviews(
    String userId, {
    String? type,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await HttpClient.instance.get(
        '/reviews/users/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(ReviewListResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, bool>> canReviewOrder(String orderId) async {
    try {
      final response = await HttpClient.instance.get(
        '/reviews/orders/$orderId/can-review',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(response.data['data']['canReview'] as bool);
      } else {
        return const Right(false);
      }
    } catch (e) {
      return const Right(false);
    }
  }
}
