import '../../../../shared/errors/failures/failures.dart';
import '../../../../shared/templates/usecase.dart';
import '../repositories/i_auth_repository.dart';

class LogoutUsecase implements Usecase<void, NoParams> {
  final IAuthRepository _repository;

  LogoutUsecase(this._repository);

  @override
  UsecaseResponse<Failure, void> call(NoParams params) async {
    return await _repository.logout();
  }
}
