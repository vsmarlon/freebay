import 'package:freebay/shared/either/either.dart';

import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';

class BlockService {
  Future<Either<Failure, BlockListResponse>> getBlockedUsers({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/blocked',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(BlockListResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, BlockResponse>> block(String userId) async {
    try {
      final response = await HttpClient.instance.post('/users/$userId/block');

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && response.data != null) {
        return Right(BlockResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, UnblockResponse>> unblock(String userId) async {
    try {
      final response = await HttpClient.instance.delete('/users/$userId/block');

      if (response.statusCode == 200 && response.data != null) {
        return Right(UnblockResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }
}
