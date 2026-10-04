import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

typedef GoogleAuthParams = ({String idToken, int authenticationAttempt});

class GoogleAuthUsecase implements Usecase<UserEntity, GoogleAuthParams> {
  final AuthRepository _repository;

  GoogleAuthUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(GoogleAuthParams params) async {
    return await _repository.googleAuth(
      params.idToken,
      authenticationAttempt: params.authenticationAttempt,
    );
  }
}
