import '../../../../shared/errors/failures/failures.dart';
import '../../../../shared/templates/usecase.dart';
import '../repositories/i_auth_repository.dart';
import '../../data/entities/user_entity.dart';

class RegisterParams {
  final String email;
  final String password;
  final String displayName;

  RegisterParams(
      {required this.email, required this.password, required this.displayName});
}

class RegisterUsecase implements Usecase<UserEntity, RegisterParams> {
  final IAuthRepository _repository;

  RegisterUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(RegisterParams params) async {
    return await _repository.register(
        params.email, params.password, params.displayName);
  }
}
