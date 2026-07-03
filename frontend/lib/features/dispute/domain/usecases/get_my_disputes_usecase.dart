import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/domain/repositories/i_dispute_repository.dart';

class GetMyDisputesUsecase implements NoParamsUsecase<List<DisputeEntity>> {
  final IDisputeRepository _repository;

  GetMyDisputesUsecase(this._repository);

  @override
  UsecaseResponse<Failure, List<DisputeEntity>> call() {
    return _repository.getMyDisputes();
  }
}
