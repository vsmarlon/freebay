import '../../../../shared/errors/failures/failures.dart';
import '../../../../shared/templates/usecase.dart';
import '../repositories/i_auth_repository.dart';
import '../../data/entities/user_entity.dart';

class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;

  LoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
}

class LoginUsecase implements Usecase<UserEntity, LoginParams> {
  final IAuthRepository _repository;

  LoginUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(LoginParams params) async {
    return await _repository.login(
      params.email,
      params.password,
      params.rememberMe,
    );
  }
}
