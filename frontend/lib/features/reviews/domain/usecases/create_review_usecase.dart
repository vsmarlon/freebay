import 'dart:io';

import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/domain/repositories/review_repository.dart';
import 'package:freebay/shared/services/image_upload_service.dart';

class CreateReviewParams {
  final String orderId;
  final String reviewedId;
  final ReviewType type;
  final int score;
  final String? comment;
  final List<String> imagePaths;

  CreateReviewParams({
    required this.orderId,
    required this.reviewedId,
    required this.type,
    required this.score,
    this.comment,
    this.imagePaths = const [],
  });
}

class CreateReviewUsecase implements Usecase<ReviewEntity, CreateReviewParams> {
  final ReviewRepository _repository;

  CreateReviewUsecase(this._repository);

  @override
  Future<Either<Failure, ReviewEntity>> call(CreateReviewParams params) async {
    final imageIds = <String>[];
    for (final path in params.imagePaths) {
      final filename = path.split(Platform.pathSeparator).last;
      final MultipartFile file;
      try {
        file = await ImageUploadService.compressedMultipartFile(
          path,
          filename: filename,
        );
      } catch (_) {
        return const Left(ServerFailure('Erro ao processar imagem.'));
      }

      final upload = await _repository.uploadReviewImage(
        orderId: params.orderId,
        file: file,
      );
      if (upload.isLeft) return Left(upload.leftOrNull!);
      imageIds.add(upload.rightOrNull ?? '');
    }

    return _repository.createReview(
      orderId: params.orderId,
      reviewedId: params.reviewedId,
      type: params.type,
      score: params.score,
      comment: params.comment,
      imageIds: imageIds,
    );
  }
}
