import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/data/services/dispute_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class DisputeRepository {
  final DisputeService _service;

  DisputeRepository(this._service);

  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId) {
    return _service.getDispute(disputeId);
  }

  Future<Either<Failure, List<DisputeEntity>>> getMyDisputes() {
    return _service.getMyDisputes();
  }

  Future<Either<Failure, DisputeEntity>> createDispute(
    String orderId,
    String reason,
  ) {
    return _service.createDispute(orderId, reason);
  }

  Future<Either<Failure, bool>> submitEvidence(
    String disputeId,
    String evidence,
  ) {
    return _service.submitEvidence(disputeId, evidence);
  }
}
