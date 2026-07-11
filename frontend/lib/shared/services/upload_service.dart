import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' show basename;
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/http_client.dart';

class UploadService {
  static Future<Either<Failure, String>> uploadFile(
    File file,
    String context,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: basename(file.path),
        ),
      });
      final response = await HttpClient.instance.post(
        '/uploads?context=$context',
        data: formData,
      );
      if (response.statusCode == 201 && response.data != null) {
        final url = relativePathFromResponse(
          response.data['data'] as Map<String, dynamic>,
        );
        if (url == null) {
          return const Left(ServerFailure('URL inválida na resposta'));
        }
        return Right(url);
      }
      return const Left(ServerFailure('Falha ao enviar arquivo'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        return const Left(ServerFailure('Arquivo muito grande. Máximo: 10 MB'));
      }
      return const Left(ServerFailure('Erro de conexão ao enviar arquivo'));
    } catch (_) {
      return const Left(ServerFailure('Erro ao enviar arquivo'));
    }
  }

  static String? relativePathFromResponse(Map<String, dynamic> data) {
    final url = data['url'];
    return url is String ? url : null;
  }
}
