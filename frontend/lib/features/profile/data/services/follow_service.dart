import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';

import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';

class FollowService extends BaseHttpRepository {
  FollowService({super.client});

  Future<Either<Failure, FollowResponse>> follow(String userId) async {
    try {
      final res = await client.post('/users/$userId/follow');
      final root = res.data;
      final extracted = root is Map && root.containsKey('data')
          ? root['data']
          : root;
      if (extracted is Map) {
        return Right(
          FollowResponse.fromJson(Map<String, dynamic>.from(extracted)),
        );
      }
      return const Left(ServerFailure('Resposta inválida do servidor.'));
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['error'] is Map
          ? data['error']['message']?.toString()
          : (data is Map && data['message'] != null
                ? data['message']?.toString()
                : null);
      if (e.response?.statusCode == 400 &&
          (msg == 'Already following' ||
              (msg?.contains('Already following') ?? false))) {
        final statusRes = await getFollowStatus(userId);
        return statusRes.fold(
          (_) => const Right(
            FollowResponse(
              following: true,
              followersCount: 0,
              followingCount: 0,
            ),
          ),
          (s) => Right(
            FollowResponse(
              following: true,
              followersCount: s.followersCount,
              followingCount: s.followingCount,
            ),
          ),
        );
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, FollowResponse>> unfollow(String userId) async {
    try {
      final res = await client.patch('/users/$userId/unfollow');
      final root = res.data;
      final extracted = root is Map && root.containsKey('data')
          ? root['data']
          : root;
      if (extracted is Map) {
        return Right(
          FollowResponse.fromJson(Map<String, dynamic>.from(extracted)),
        );
      }
      return const Left(ServerFailure('Resposta inválida do servidor.'));
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['error'] is Map
          ? data['error']['message']?.toString()
          : (data is Map && data['message'] != null
                ? data['message']?.toString()
                : null);
      if (e.response?.statusCode == 400 &&
          (msg == 'Not following' ||
              (msg?.contains('Not following') ?? false))) {
        final statusRes = await getFollowStatus(userId);
        return statusRes.fold(
          (_) => const Right(
            FollowResponse(
              following: false,
              followersCount: 0,
              followingCount: 0,
            ),
          ),
          (s) => Right(
            FollowResponse(
              following: false,
              followersCount: s.followersCount,
              followingCount: s.followingCount,
            ),
          ),
        );
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, FollowStatusResponse>> getFollowStatus(
    String userId,
  ) => safeGet<FollowStatusResponse>(
    '/users/$userId/is-following',
    extractKey: 'data',
    fromJson: FollowStatusResponse.fromJson,
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
}
