import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/dispute/domain/repositories/i_dispute_repository.dart';

class SubmitEvidenceParams {
  final String disputeId;
  final String evidence;

  SubmitEvidenceParams({required this.disputeId, required this.evidence});
}

class SubmitEvidenceUsecase implements Usecase<bool, SubmitEvidenceParams> {
  final IDisputeRepository _repository;

  SubmitEvidenceUsecase(this._repository);

  @override
  UsecaseResponse<Failure, bool> call(SubmitEvidenceParams params) {
    return _repository.submitEvidence(params.disputeId, params.evidence);
  }
}
