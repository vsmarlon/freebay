import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/domain/repositories/i_dispute_repository.dart';

class CreateDisputeParams {
  final String orderId;
  final String reason;

  CreateDisputeParams({required this.orderId, required this.reason});
}

class CreateDisputeUsecase
    implements Usecase<DisputeEntity, CreateDisputeParams> {
  final IDisputeRepository _repository;

  CreateDisputeUsecase(this._repository);

  @override
  UsecaseResponse<Failure, DisputeEntity> call(CreateDisputeParams params) {
    return _repository.createDispute(params.orderId, params.reason);
  }
}
