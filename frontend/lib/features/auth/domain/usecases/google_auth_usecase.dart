import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class GoogleAuthUsecase implements Usecase<UserEntity, String> {
  final IAuthRepository _repository;

  GoogleAuthUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(String idToken) async {
    return await _repository.googleAuth(idToken);
  }
}
