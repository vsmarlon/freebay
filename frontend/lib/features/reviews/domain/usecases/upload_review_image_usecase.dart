import 'dart:io';

import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/reviews/domain/repositories/review_repository.dart';
import 'package:freebay/shared/services/image_upload_service.dart';

class UploadReviewImageParams {
  final String orderId;
  final String filePath;

  UploadReviewImageParams({required this.orderId, required this.filePath});
}

class UploadReviewImageUsecase
    implements Usecase<String, UploadReviewImageParams> {
  final ReviewRepository _repository;

  UploadReviewImageUsecase(this._repository);

  @override
  Future<Either<Failure, String>> call(UploadReviewImageParams params) async {
    final filename = params.filePath.split(Platform.pathSeparator).last;
    final MultipartFile file;
    try {
      file = await ImageUploadService.compressedMultipartFile(
        params.filePath,
        filename: filename,
      );
    } catch (_) {
      return const Left(ServerFailure('Erro ao processar imagem.'));
    }
    return _repository.uploadReviewImage(orderId: params.orderId, file: file);
  }
}
