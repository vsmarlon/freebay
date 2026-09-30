import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';

typedef CloseFriendCandidate = ({UserBrief user, bool isCloseFriend});

class ProfileRepository {
  final Dio client;

  ProfileRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, List<CloseFriendCandidate>>> getCloseFriendCandidates({
    String search = '',
    bool selected = false,
    int offset = 0,
    int limit = 20,
  }) => requestEither(
    () => client.get(
      '/users/me/close-friends/candidates',
      queryParameters: {
        'q': search,
        if (selected) 'selected': 'true',
        'offset': offset,
        'limit': limit,
      },
    ),
    decoder: (response) => Right([
      for (final value in response.data['data']['users'] as List)
        (
          user: UserBrief.fromJson(Map<String, dynamic>.from(value as Map)),
          isCloseFriend: value['isCloseFriend'] == true,
        ),
    ]),
  );

  Future<Either<Failure, void>> setCloseFriend(
    String memberId, {
    required bool add,
  }) => requestEither<void>(
    () => add
        ? client.post('/users/me/close-friends/$memberId')
        : client.patch('/users/me/close-friends/$memberId/remove'),
    decoder: (_) => const Right(null),
  );

  Future<Either<Failure, UserEntity>> getProfile(String userId) =>
      requestEither(
        () => client.get('/users/$userId'),
        decoder: (response) =>
            Right(UserEntity.fromJson(response.data['data'])),
      );

  Future<Either<Failure, UserStatsEntity>> getProfileStats() => requestEither(
    () => client.get('/users/me/stats'),
    decoder: (response) =>
        Right(UserStatsEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, FollowListResponse>> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) => requestEither(
    () => client.get(
      '/users/$userId/followers',
      queryParameters: {'limit': limit, 'offset': offset},
    ),
    decoder: (response) =>
        Right(FollowListResponse.fromJson(response.data['data'])),
  );

  Future<Either<Failure, FollowListResponse>> getFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) => requestEither(
    () => client.get(
      '/users/$userId/following',
      queryParameters: {'limit': limit, 'offset': offset},
    ),
    decoder: (response) =>
        Right(FollowListResponse.fromJson(response.data['data'])),
  );

  Future<Either<Failure, UserEntity>> updateAvatar(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'avatar': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'avatar.jpg',
        ),
      });
      return requestEither(
        () => client.post(
          '/users/me/avatar',
          data: data,
          options: Options(contentType: 'multipart/form-data'),
        ),
        decoder: (response) =>
            Right(UserEntity.fromJson(response.data['data'])),
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
  }) => requestEither(
    () => client.patch(
      '/users/me',
      data: {
        'displayName': ?displayName,
        'username': ?username,
        'bio': ?bio,
        'city': ?city,
        'state': ?state,
        'cpf': ?cpf,
      },
    ),
    decoder: (response) => Right(UserEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, UserEntity>> updateBanner(String imagePath) async {
    try {
      final data = FormData.fromMap({
        'banner': await ImageUploadService.compressedMultipartFile(
          imagePath,
          filename: 'banner.jpg',
        ),
      });
      return requestEither(
        () => client.post(
          '/users/me/banner',
          data: data,
          options: Options(contentType: 'multipart/form-data'),
        ),
        decoder: (response) =>
            Right(UserEntity.fromJson(response.data['data'])),
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, void>> registerPhone(String phone) =>
      requestEither<void>(
        () => client.post('/users/me/phone', data: {'phone': phone}),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, UserEntity>> verifyPhone(String code) => requestEither(
    () => client.post('/users/me/phone/verify', data: {'code': code}),
    decoder: (response) => Right(UserEntity.fromJson(response.data['data'])),
  );
}
