import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class CreateBugReportUsecase {
  Future<Either<Failure, void>> call({
    required String description,
    String? appVersion,
    String? platform,
    String? screenContext,
  }) async {
    try {
      await HttpClient.instance.post('/bug-reports', data: {
        'description': description,
        if (appVersion != null) 'appVersion': appVersion,
        if (platform != null) 'platform': platform,
        if (screenContext != null) 'screenContext': screenContext,
      });
      return const Right(null);
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data?['error']?['message'] ??
            'Erro ao enviar relatório';
        return Left(ServerFailure(msg));
      }
      return const Left(ServerFailure('Erro de conexão'));
    }
  }
}
