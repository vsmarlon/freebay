import 'package:freebay/shared/either/either.dart';

import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';

class BlockService extends BaseHttpRepository {
  BlockService({super.client});
  Future<Either<Failure, BlockListResponse>> getBlockedUsers({
    int limit = 20,
    int offset = 0,
  }) => safeGet<BlockListResponse>(
    '/users/blocked',
    queryParameters: {'limit': limit, 'offset': offset},
    extractKey: 'data',
    fromJson: BlockListResponse.fromJson,
  );

  Future<Either<Failure, BlockResponse>> block(String userId) =>
      safePost<BlockResponse>(
        '/users/$userId/block',
        extractKey: 'data',
        fromJson: BlockResponse.fromJson,
      );

  Future<Either<Failure, UnblockResponse>> unblock(String userId) =>
      safePatch<UnblockResponse>(
        '/users/$userId/unblock',
        extractKey: 'data',
        fromJson: UnblockResponse.fromJson,
      );
}
