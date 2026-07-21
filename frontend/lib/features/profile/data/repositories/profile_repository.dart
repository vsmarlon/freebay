import 'package:freebay/shared/either/either.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
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
          ServerFailure('Não foi possível carregar as estatísticas.'),
        );
      }
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<FollowerEntity>>> getFollowers(
    String userId,
  ) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/$userId/followers',
      );

      if (kDebugMode) {
        debugPrint('[PROFILE] getFollowers status: ${response.statusCode}');
        debugPrint('[PROFILE] getFollowers data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final usersData = (data?['users'] as List?) ?? [];
        final followers = usersData
            .map(
              (json) => FollowerEntity.fromJson(json as Map<String, dynamic>),
            )
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
    String userId,
  ) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/$userId/following',
      );

      if (kDebugMode) {
        debugPrint('[PROFILE] getFollowing status: ${response.statusCode}');
        debugPrint('[PROFILE] getFollowing data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final usersData = (data?['users'] as List?) ?? [];
        final following = usersData
            .map(
              (json) => FollowerEntity.fromJson(json as Map<String, dynamic>),
            )
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
  Future<Either<Failure, UserEntity>> updateAvatar(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'avatar': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'avatar.jpg',
        ),
      });

      final response = await HttpClient.instance.post(
        '/users/me/avatar',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(UserEntity.fromJson(response.data['data']));
      }
      return const Left(ServerFailure('Não foi possível atualizar a foto.'));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PROFILE] updateAvatar DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PROFILE] updateAvatar error: $e');
        debugPrint('[PROFILE] updateAvatar stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? city,
    String? state,
    String? cpf,
  }) async {
    try {
      final response = await HttpClient.instance.patch(
        '/users/me',
        data: {
          'displayName': ?displayName,
          'username': ?username,
          'bio': ?bio,
          'city': ?city,
          'state': ?state,
          'cpf': ?cpf,
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

  @override
  Future<Either<Failure, UserEntity>> updateBanner(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'banner': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'banner.jpg',
        ),
      });

      final response = await HttpClient.instance.post(
        '/users/me/banner',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(UserEntity.fromJson(response.data['data']));
      }
      return const Left(
        ServerFailure('Não foi possível atualizar a imagem de fundo.'),
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PROFILE] updateBanner DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PROFILE] updateBanner error: $e');
        debugPrint('[PROFILE] updateBanner stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> registerPhone(String phone) async {
    try {
      final response = await HttpClient.instance.post(
        '/users/me/phone',
        data: {'phone': phone},
      );
      if (response.statusCode == 200) {
        return const Right(null);
      }
      return const Left(
        ServerFailure('Não foi possível solicitar código de verificação.'),
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PROFILE] registerPhone DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PROFILE] registerPhone error: $e');
        debugPrint('[PROFILE] registerPhone stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyPhone(String code) async {
    try {
      final response = await HttpClient.instance.post(
        '/users/me/phone/verify',
        data: {'code': code},
      );
      if (response.statusCode == 200 && response.data != null) {
        return Right(UserEntity.fromJson(response.data['data']));
      }
      return const Left(
        ServerFailure('Código de verificação incorreto ou expirado.'),
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PROFILE] verifyPhone DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PROFILE] verifyPhone error: $e');
        debugPrint('[PROFILE] verifyPhone stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }
}
