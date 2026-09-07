import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class GetCurrentUserUsecase implements NoParamsUsecase<UserEntity> {
  final AuthRepository _repository;

  GetCurrentUserUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call() async {
    return await _repository.getCurrentUser();
  }
}
