import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;
  final int authenticationAttempt;

  LoginParams({
    required this.email,
    required this.password,
    required this.authenticationAttempt,
    this.rememberMe = false,
  });
}

class LoginUsecase implements Usecase<UserEntity, LoginParams> {
  final AuthRepository _repository;

  LoginUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(LoginParams params) async {
    return await _repository.login(
      params.email,
      params.password,
      params.rememberMe,
      authenticationAttempt: params.authenticationAttempt,
    );
  }
}
