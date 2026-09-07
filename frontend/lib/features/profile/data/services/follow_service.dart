import 'package:freebay/shared/either/either.dart';

import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';

class FollowService extends BaseHttpRepository {
  FollowService({super.client});

  Future<Either<Failure, FollowResponse>> follow(String userId) =>
      safePost<FollowResponse>(
        '/users/$userId/follow',
        extractKey: 'data',
        fromJson: FollowResponse.fromJson,
      );

  Future<Either<Failure, FollowResponse>> unfollow(String userId) =>
      safePatch<FollowResponse>(
        '/users/$userId/unfollow',
        extractKey: 'data',
        fromJson: FollowResponse.fromJson,
      );

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
