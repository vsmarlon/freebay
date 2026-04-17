import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class BlockService {
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

  Future<Either<Failure, BlockListResponse>> getBlockedUsers(
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await HttpClient.instance.get(
        '/users/blocked',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(BlockListResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, UnblockResponse>> unblock(String userId) async {
    try {
      final response = await HttpClient.instance.delete('/users/$userId/block');

      if (response.statusCode == 200 && response.data != null) {
        return Right(UnblockResponse.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }
}

class BlockListUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final double reputationScore;

  BlockListUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
    required this.reputationScore,
  });

  factory BlockListUser.fromJson(Map<String, dynamic> json) {
    return BlockListUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool,
      reputationScore: (json['reputationScore'] as num).toDouble(),
    );
  }
}

class BlockListResponse {
  final List<BlockListUser> users;
  final int limit;
  final int offset;

  BlockListResponse({
    required this.users,
    required this.limit,
    required this.offset,
  });

  factory BlockListResponse.fromJson(Map<String, dynamic> json) {
    return BlockListResponse(
      users: (json['users'] as List)
          .map((e) => BlockListUser.fromJson(e))
          .toList(),
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }
}

class UnblockResponse {
  final bool blocked;

  UnblockResponse({required this.blocked});

  factory UnblockResponse.fromJson(Map<String, dynamic> json) {
    return UnblockResponse(
      blocked: json['blocked'] as bool,
    );
  }
}
