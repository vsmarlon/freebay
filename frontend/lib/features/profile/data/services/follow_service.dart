import 'package:freebay/shared/either/either.dart';

import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';

class FollowService {
  Future<Either<Failure, FollowResponse>> follow(String userId) async {
    try {
      final response = await HttpClient.instance.post('/users/$userId/follow');

      if (response.statusCode == 201 && response.data != null) {
        return Right(FollowResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, FollowResponse>> unfollow(String userId) async {
    try {
      final response = await HttpClient.instance.delete(
        '/users/$userId/follow',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, FollowStatusResponse>> getFollowStatus(
    String userId,
  ) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/$userId/is-following',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowStatusResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, FollowListResponse>> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/$userId/followers',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowListResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, FollowListResponse>> getFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/$userId/following',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowListResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }
}
