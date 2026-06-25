import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';

class CheckAuthUsecase implements NoParamsUsecase<bool> {
  final IAuthRepository _repository;

  CheckAuthUsecase(this._repository);

  @override
  UsecaseResponse<Failure, bool> call() async {
    return await _repository.isLoggedIn();
  }
}
