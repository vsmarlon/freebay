import '../../../../shared/errors/failures/failures.dart';
import '../../../../shared/templates/usecase.dart';
import '../repositories/i_auth_repository.dart';
import '../../data/entities/user_entity.dart';

class GetCurrentUserUsecase implements Usecase<UserEntity, NoParams> {
  final IAuthRepository _repository;

  GetCurrentUserUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(NoParams params) async {
    return await _repository.getCurrentUser();
  }
}
