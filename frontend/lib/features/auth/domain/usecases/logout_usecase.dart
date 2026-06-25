import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';

class LogoutUsecase implements NoParamsUsecase<void> {
  final IAuthRepository _repository;

  LogoutUsecase(this._repository);

  @override
  UsecaseResponse<Failure, void> call() async {
    return await _repository.logout();
  }
}
