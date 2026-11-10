import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract interface class DisputeRepository {
  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId);
  Future<Either<Failure, List<DisputeEntity>>> getMyDisputes();
  Future<Either<Failure, DisputeEntity>> createDispute(
    String orderId,
    String reason,
  );
  Future<Either<Failure, bool>> submitEvidence(
    String disputeId,
    String evidence,
  );
}
