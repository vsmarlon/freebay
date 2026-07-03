import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/domain/repositories/i_dispute_repository.dart';

class GetDisputeUsecase implements Usecase<DisputeEntity, String> {
  final IDisputeRepository _repository;

  GetDisputeUsecase(this._repository);

  @override
  UsecaseResponse<Failure, DisputeEntity> call(String disputeId) {
    return _repository.getDispute(disputeId);
  }
}
