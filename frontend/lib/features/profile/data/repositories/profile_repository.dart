import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';

class ProfileRepository extends BaseHttpRepository {
  ProfileRepository({super.client});

  Future<Either<Failure, UserEntity>> getProfile(String userId) =>
      safeGet<UserEntity>(
        '/users/$userId',
        extractKey: 'data',
        fromJson: UserEntity.fromJson,
      );

  Future<Either<Failure, UserStatsEntity>> getProfileStats() =>
      safeGet<UserStatsEntity>(
        '/users/me/stats',
        extractKey: 'data',
        fromJson: UserStatsEntity.fromJson,
      );

  Future<Either<Failure, FollowListResponse>> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) => safeGet<FollowListResponse>(
    '/users/$userId/followers',
    queryParameters: {'limit': limit, 'offset': offset},
    extractKey: 'data',
    fromJson: FollowListResponse.fromJson,
  );

  Future<Either<Failure, FollowListResponse>> getFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) => safeGet<FollowListResponse>(
    '/users/$userId/following',
    queryParameters: {'limit': limit, 'offset': offset},
    extractKey: 'data',
    fromJson: FollowListResponse.fromJson,
  );

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

  Future<Either<Failure, void>> registerPhone(String phone) =>
      safeVoid(() => client.post('/users/me/phone', data: {'phone': phone}));

  Future<Either<Failure, UserEntity>> verifyPhone(String code) =>
      safePost<UserEntity>(
        '/users/me/phone/verify',
        data: {'code': code},
        extractKey: 'data',
        fromJson: UserEntity.fromJson,
      );
}
