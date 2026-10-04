import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' show basename;
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/entities/uploaded_media.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';

class UploadService {
  static const _compressedImageContexts = {
    'avatar',
    'post',
    'product',
    'privatepost',
  };

  static Future<Either<Failure, UploadedMedia>> uploadMedia(
    File file,
    String context,
  ) async {
    try {
      final filename = basename(file.path);
      final multipart = _compressedImageContexts.contains(context)
          ? await ImageUploadService.compressedMultipartFile(
              file.path,
              filename: filename,
            )
          : await MultipartFile.fromFile(file.path, filename: filename);
      final response = await HttpClient.instance.post(
        '/uploads',
        queryParameters: {'context': context},
        data: FormData.fromMap({'file': multipart}),
      );
      if (response.statusCode != 201) {
        return const Left(ServerFailure('Falha ao enviar arquivo'));
      }
      final media = mediaFromResponse(response.data);
      if (media == null) {
        return const Left(ServerFailure('URL inválida na resposta'));
      }
      return Right(media);
    } on DioException catch (error) {
      if (error.response?.statusCode == 413) {
        return const Left(ServerFailure('Arquivo muito grande. Máximo: 5 MB'));
      }
      return const Left(ServerFailure('Erro de conexão ao enviar arquivo'));
    } catch (_) {
      return const Left(ServerFailure('Erro ao enviar arquivo'));
    }
  }

  static Future<Either<Failure, String>> uploadFile(
    File file,
    String context,
  ) async {
    final result = await uploadMedia(file, context);
    return result.fold(Left.new, (media) => Right(media.url));
  }

  static UploadedMedia? mediaFromResponse(Object? response) {
    final envelope = _stringKeyedMap(response);
    final data = _stringKeyedMap(envelope?['data']);
    if (data == null) return null;
    try {
      return UploadedMedia.fromJson(data);
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?>? _stringKeyedMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is! Map<Object?, Object?>) return null;
    final map = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) return null;
      map[key] = entry.value;
    }
    return map;
  }
}
