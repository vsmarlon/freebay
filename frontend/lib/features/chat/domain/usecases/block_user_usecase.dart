import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/profile/data/services/block_service.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class BlockUserUsecase {
  final BlockService _blockService;

  BlockUserUsecase(this._blockService);

  Future<Either<Failure, BlockResponse>> call(String userId) {
    return _blockService.block(userId);
  }
}
