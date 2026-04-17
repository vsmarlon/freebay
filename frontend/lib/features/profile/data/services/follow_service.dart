import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class FollowService {
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData != null && responseData is Map) {
        final errorObj = responseData['error'];
        if (errorObj != null && errorObj is Map) {
          final message = errorObj['message'];
          if (message != null) return message.toString();
        }
      }
    }
    return 'Erro ao conectar com o servidor.';
  }

  Future<Either<Failure, FollowResponse>> follow(String userId) async {
    try {
      final response = await HttpClient.instance.post('/users/$userId/follow');

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, FollowResponse>> unfollow(String userId) async {
    try {
      final response =
          await HttpClient.instance.delete('/users/$userId/follow');

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, FollowStatusResponse>> getFollowStatus(
      String userId) async {
    try {
      final response =
          await HttpClient.instance.get('/users/$userId/is-following');

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowStatusResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, FollowListResponse>> getFollowers(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/$userId/followers',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowListResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, FollowListResponse>> getFollowing(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/$userId/following',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(FollowListResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }
}

class FollowResponse {
  final bool following;
  final int followersCount;
  final int followingCount;

  FollowResponse({
    required this.following,
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowResponse.fromJson(Map<String, dynamic> json) {
    return FollowResponse(
      following: json['following'] as bool,
      followersCount: json['followersCount'] as int,
      followingCount: json['followingCount'] as int,
    );
  }
}

class FollowStatusResponse {
  final bool isFollowing;
  final int followersCount;
  final int followingCount;

  FollowStatusResponse({
    required this.isFollowing,
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowStatusResponse.fromJson(Map<String, dynamic> json) {
    return FollowStatusResponse(
      isFollowing: json['isFollowing'] as bool,
      followersCount: json['followersCount'] as int,
      followingCount: json['followingCount'] as int,
    );
  }
}

class FollowListUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final double reputationScore;

  FollowListUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
    required this.reputationScore,
  });

  factory FollowListUser.fromJson(Map<String, dynamic> json) {
    return FollowListUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool,
      reputationScore: (json['reputationScore'] as num).toDouble(),
    );
  }
}

class FollowListResponse {
  final List<FollowListUser> users;
  final int total;
  final int limit;
  final int offset;

  FollowListResponse({
    required this.users,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory FollowListResponse.fromJson(Map<String, dynamic> json) {
    return FollowListResponse(
      users: (json['users'] as List)
          .map((e) => FollowListUser.fromJson(e))
          .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }
}
