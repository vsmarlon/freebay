import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/profile/domain/repositories/i_profile_repository.dart';

class GetProfileUsecase implements Usecase<UserEntity, String> {
  final IProfileRepository _repository;

  GetProfileUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(String userId) async {
    return await _repository.getProfile(userId);
  }
}
