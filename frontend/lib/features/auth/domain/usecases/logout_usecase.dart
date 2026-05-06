import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';

class LogoutUsecase implements Usecase<void, NoParams> {
  final IAuthRepository _repository;

  LogoutUsecase(this._repository);

  @override
  UsecaseResponse<Failure, void> call(NoParams params) async {
    return await _repository.logout();
  }
}
