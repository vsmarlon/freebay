import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';

class ProfileRepository extends BaseHttpRepository
    implements IProfileRepository {
  ProfileRepository({super.client});

  @override
  Future<Either<Failure, UserEntity>> getProfile(String userId) =>
      safeGet<UserEntity>(
        '/users/$userId',
        extractKey: 'data',
        fromJson: UserEntity.fromJson,
      );

  @override
  Future<Either<Failure, UserStatsEntity>> getProfileStats() =>
      safeGet<UserStatsEntity>(
        '/users/me/stats',
        extractKey: 'data',
        fromJson: UserStatsEntity.fromJson,
      );

  @override
  Future<Either<Failure, List<FollowerEntity>>> getFollowers(String userId) =>
      safeGetList<FollowerEntity>(
        '/users/$userId/followers',
        listKey: 'data.users',
        fromJson: FollowerEntity.fromJson,
      );

  @override
  Future<Either<Failure, List<FollowerEntity>>> getFollowing(String userId) =>
      safeGetList<FollowerEntity>(
        '/users/$userId/following',
        listKey: 'data.users',
        fromJson: FollowerEntity.fromJson,
      );

  @override
  Future<Either<Failure, UserEntity>> updateAvatar(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'avatar': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'avatar.jpg',
        ),
      });
      return safePost<UserEntity>(
        '/users/me/avatar',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
        extractKey: 'data',
        fromJson: UserEntity.fromJson,
      );
    } catch (_) {
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
  }) => safePatch<UserEntity>(
    '/users/me',
    data: {
      'displayName': ?displayName,
      'username': ?username,
      'bio': ?bio,
      'city': ?city,
      'state': ?state,
      'cpf': ?cpf,
    },
    extractKey: 'data',
    fromJson: UserEntity.fromJson,
  );

  @override
  Future<Either<Failure, UserEntity>> updateBanner(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'banner': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'banner.jpg',
        ),
      });
      return safePost<UserEntity>(
        '/users/me/banner',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
        extractKey: 'data',
        fromJson: UserEntity.fromJson,
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> registerPhone(String phone) =>
      safeVoid(() => client.post('/users/me/phone', data: {'phone': phone}));

  @override
  Future<Either<Failure, UserEntity>> verifyPhone(String code) =>
      safePost<UserEntity>(
        '/users/me/phone/verify',
        data: {'code': code},
        extractKey: 'data',
        fromJson: UserEntity.fromJson,
      );
}
