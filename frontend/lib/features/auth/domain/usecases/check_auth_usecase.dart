import '../../../../shared/errors/failures/failures.dart';
import '../../../../shared/templates/usecase.dart';
import '../repositories/i_auth_repository.dart';

class CheckAuthUsecase implements Usecase<bool, NoParams> {
  final IAuthRepository _repository;

  CheckAuthUsecase(this._repository);

  @override
  UsecaseResponse<Failure, bool> call(NoParams params) async {
    return await _repository.isLoggedIn();
  }
}
