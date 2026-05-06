import 'package:dartz/dartz.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';

class RequestPasswordRecoveryParams {
  final String email;

  RequestPasswordRecoveryParams({required this.email});
}

class RequestPasswordRecoveryUsecase implements Usecase<void, RequestPasswordRecoveryParams> {
  final IAuthRepository _repository;

  RequestPasswordRecoveryUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(RequestPasswordRecoveryParams params) {
    return _repository.requestPasswordRecovery(params.email);
  }
}
