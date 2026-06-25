import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class GuestLoginUsecase implements NoParamsUsecase<UserEntity> {
  final IAuthRepository _repository;

  GuestLoginUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call() async {
    return await _repository.loginAsGuest();
  }
}
