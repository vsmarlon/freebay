import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';

class VerifyPasswordRecoveryCodeParams {
  final String email;
  final String code;

  VerifyPasswordRecoveryCodeParams({required this.email, required this.code});
}

class VerifyPasswordRecoveryCodeUsecase
    implements Usecase<bool, VerifyPasswordRecoveryCodeParams> {
  final AuthRepository _repository;

  VerifyPasswordRecoveryCodeUsecase(this._repository);

  @override
  Future<Either<Failure, bool>> call(VerifyPasswordRecoveryCodeParams params) {
    return _repository.verifyPasswordRecoveryCode(params.email, params.code);
  }
}
