import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';

class DisputeService {
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

  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId) async {
    try {
      final response = await HttpClient.instance.get('/disputes/$disputeId');
      if (response.statusCode == 200 && response.data != null) {
        final disputeData = response.data['data']?['dispute'] ?? response.data['dispute'];
        return Right(DisputeEntity.fromJson(disputeData as Map<String, dynamic>));
      }
      return Left(ServerFailure(_extractErrorMessage(response.data)));
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, List<DisputeEntity>>> getMyDisputes() async {
    try {
      final response = await HttpClient.instance.get('/disputes');
      if (response.statusCode == 200 && response.data != null) {
        final disputesList = response.data['data']?['disputes'] as List<dynamic>?;
        final disputes = disputesList?.map((e) => DisputeEntity.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        return Right(disputes);
      }
      return Left(ServerFailure(_extractErrorMessage(response.data)));
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, DisputeEntity>> createDispute(String orderId, String reason) async {
    try {
      final response = await HttpClient.instance.post(
        '/disputes',
        data: {'orderId': orderId, 'reason': reason},
      );
      if (response.statusCode == 201 && response.data != null) {
        final disputeData = response.data['data'] as Map<String, dynamic>?;
        return Right(DisputeEntity.fromJson(disputeData ?? response.data as Map<String, dynamic>));
      }
      return Left(ServerFailure(_extractErrorMessage(response.data)));
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, bool>> submitEvidence(String disputeId, String evidence) async {
    try {
      final response = await HttpClient.instance.post(
        '/disputes/$disputeId/evidence',
        data: {'evidence': evidence},
      );
      if (response.statusCode == 200) {
        return Right(true);
      }
      return Left(ServerFailure(_extractErrorMessage(response.data)));
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }
}
