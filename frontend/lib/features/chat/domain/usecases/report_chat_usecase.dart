import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class ReportChatUsecase {
  Future<Either<Failure, void>> call({
    required String targetId,
    required String targetType,
    required String reason,
    String? description,
  }) async {
    try {
      await HttpClient.instance.post('/reports', data: {
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'description': description ?? '',
      });
      return const Right(null);
    } catch (e) {
      if (e is DioException) {
        final msg =
            e.response?.data?['error']?['message'] ?? 'Erro ao enviar denúncia';
        return Left(ServerFailure(msg));
      }
      return const Left(ServerFailure('Erro de conexão'));
    }
  }
}
