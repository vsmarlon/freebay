import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';

class ResetPasswordParams {
  final String email;
  final String code;
  final String newPassword;

  ResetPasswordParams({
    required this.email,
    required this.code,
    required this.newPassword,
  });
}

class ResetPasswordUsecase implements Usecase<void, ResetPasswordParams> {
  final AuthRepository _repository;

  ResetPasswordUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) {
    return _repository.resetPassword(
      params.email,
      params.code,
      params.newPassword,
    );
  }
}
