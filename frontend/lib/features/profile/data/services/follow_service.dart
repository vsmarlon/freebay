import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';

import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';

class FollowService {
  final Dio client;

  FollowService({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, FollowResponse>> _toggle(
    String userId, {
    required bool following,
    required Future<Response> Function() request,
    required String expectedError,
  }) async {
    try {
      final res = await request();
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
      final msg = _errorMessage(e);
      if (e.response?.statusCode == 400 &&
          (msg == expectedError || (msg?.contains(expectedError) ?? false))) {
        final statusRes = await getFollowStatus(userId);
        return statusRes.fold(
          (_) => Right(
            FollowResponse(
              following: following,
              followersCount: 0,
              followingCount: 0,
            ),
          ),
          (s) => Right(
            FollowResponse(
              following: following,
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

  Future<Either<Failure, FollowResponse>> follow(String userId) => _toggle(
    userId,
    following: true,
    expectedError: 'Already following',
    request: () => client.post('/users/$userId/follow'),
  );

  Future<Either<Failure, FollowResponse>> unfollow(String userId) => _toggle(
    userId,
    following: false,
    expectedError: 'Not following',
    request: () => client.patch('/users/$userId/unfollow'),
  );

  String? _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is! Map) return null;
    final nestedError = data['error'];
    if (nestedError is Map && nestedError['message'] != null) {
      return nestedError['message'].toString();
    }
    return data['message']?.toString();
  }

  Future<Either<Failure, FollowStatusResponse>> getFollowStatus(
    String userId,
  ) => requestEither(
    () => client.get('/users/$userId/is-following'),
    decoder: (response) =>
        Right(FollowStatusResponse.fromJson(response.data['data'])),
  );

  Future<Either<Failure, FollowListResponse>> _getList(
    String userId, {
    required String relation,
    required int limit,
    required int offset,
  }) => requestEither(
    () => client.get(
      '/users/$userId/$relation',
      queryParameters: {'limit': limit, 'offset': offset},
    ),
    decoder: (response) =>
        Right(FollowListResponse.fromJson(response.data['data'])),
  );

  Future<Either<Failure, FollowListResponse>> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) => _getList(userId, relation: 'followers', limit: limit, offset: offset);

  Future<Either<Failure, FollowListResponse>> getFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) => _getList(userId, relation: 'following', limit: limit, offset: offset);
}
