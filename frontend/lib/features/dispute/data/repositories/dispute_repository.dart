import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/data/services/dispute_service.dart';
import 'package:freebay/features/dispute/domain/repositories/i_dispute_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class DisputeRepository implements IDisputeRepository {
  final DisputeService _service;

  DisputeRepository(this._service);

  @override
  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId) {
    return _service.getDispute(disputeId);
  }

  @override
  Future<Either<Failure, List<DisputeEntity>>> getMyDisputes() {
    return _service.getMyDisputes();
  }

  @override
  Future<Either<Failure, DisputeEntity>> createDispute(
    String orderId,
    String reason,
  ) {
    return _service.createDispute(orderId, reason);
  }

  @override
  Future<Either<Failure, bool>> submitEvidence(
    String disputeId,
    String evidence,
  ) {
    return _service.submitEvidence(disputeId, evidence);
  }
}
