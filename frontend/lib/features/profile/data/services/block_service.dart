import 'package:freebay/shared/either/either.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';

class BlockService {
  final Dio client;

  BlockService({Dio? client}) : client = client ?? HttpClient.instance;
  Future<Either<Failure, BlockListResponse>> getBlockedUsers({
    int limit = 20,
    int offset = 0,
  }) => requestEither(
    () => client.get(
      '/users/blocked',
      queryParameters: {'limit': limit, 'offset': offset},
    ),
    decoder: (response) =>
        Right(BlockListResponse.fromJson(response.data['data'])),
  );

  Future<Either<Failure, BlockResponse>> block(String userId) => requestEither(
    () => client.post('/users/$userId/block'),
    decoder: (response) => Right(BlockResponse.fromJson(response.data['data'])),
  );

  Future<Either<Failure, UnblockResponse>> unblock(String userId) =>
      requestEither(
        () => client.patch('/users/$userId/unblock'),
        decoder: (response) =>
            Right(UnblockResponse.fromJson(response.data['data'])),
      );
}
