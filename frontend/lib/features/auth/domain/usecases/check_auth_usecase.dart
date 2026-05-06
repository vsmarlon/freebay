import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';

class CheckAuthUsecase implements Usecase<bool, NoParams> {
  final IAuthRepository _repository;

  CheckAuthUsecase(this._repository);

  @override
  UsecaseResponse<Failure, bool> call(NoParams params) async {
    return await _repository.isLoggedIn();
  }
}
