import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';

class ProfileRepository implements IProfileRepository {
  @override
  Future<Either<Failure, UserEntity>> getProfile(String userId) async {
    try {
      final response = await HttpClient.instance.get('/users/$userId');
      if (response.statusCode == 200 && response.data != null) {
        return Right(UserEntity.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Não foi possível carregar o perfil.'));
      }
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserStatsEntity>> getProfileStats() async {
    try {
      final response = await HttpClient.instance.get('/users/me/stats');
      if (response.statusCode == 200 && response.data != null) {
        return Right(UserStatsEntity.fromJson(response.data['data']));
      } else {
        return const Left(
            ServerFailure('Não foi possível carregar as estatísticas.'));
      }
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<FollowerEntity>>> getFollowers(
      String userId) async {
    try {
      final response =
          await HttpClient.instance.get('/users/$userId/followers');

      if (kDebugMode) {
        debugPrint('[PROFILE] getFollowers status: ${response.statusCode}');
        debugPrint('[PROFILE] getFollowers data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final usersData = (data?['users'] as List?) ?? [];
        final followers = usersData
            .map(
                (json) => FollowerEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(followers);
      }
      return const Left(ServerFailure('Não foi possível carregar seguidores.'));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PROFILE] getFollowers error: $e');
        debugPrint('[PROFILE] getFollowers stack: $stack');
      }
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<FollowerEntity>>> getFollowing(
      String userId) async {
    try {
      final response =
          await HttpClient.instance.get('/users/$userId/following');

      if (kDebugMode) {
        debugPrint('[PROFILE] getFollowing status: ${response.statusCode}');
        debugPrint('[PROFILE] getFollowing data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final usersData = (data?['users'] as List?) ?? [];
        final following = usersData
            .map(
                (json) => FollowerEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(following);
      }
      return const Left(ServerFailure('Não foi possível carregar seguindo.'));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PROFILE] getFollowing error: $e');
        debugPrint('[PROFILE] getFollowing stack: $stack');
      }
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? bio,
    String? city,
    String? state,
  }) async {
    try {
      final response = await HttpClient.instance.patch(
        '/users/me',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (bio != null) 'bio': bio,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return Right(UserEntity.fromJson(response.data['data']));
      }
      return const Left(ServerFailure('Não foi possível atualizar o perfil.'));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
