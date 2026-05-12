import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class GetCurrentUserUsecase implements Usecase<UserEntity, NoParams> {
  final IAuthRepository _repository;

  GetCurrentUserUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(NoParams params) async {
    return await _repository.getCurrentUser();
  }
}
