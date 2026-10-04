import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class RegisterParams {
  final String email;
  final String password;
  final String displayName;
  final String username;
  final int authenticationAttempt;

  RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
    required this.username,
    required this.authenticationAttempt,
  });
}

class RegisterUsecase implements Usecase<UserEntity, RegisterParams> {
  final AuthRepository _repository;

  RegisterUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(RegisterParams params) async {
    return await _repository.register(
      params.email,
      params.password,
      params.displayName,
      params.username,
      authenticationAttempt: params.authenticationAttempt,
    );
  }
}
