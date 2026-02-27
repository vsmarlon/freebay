import 'package:freebay/features/auth/data/entities/user_entity.dart';
import '../../../../shared/errors/failures/failures.dart';
import '../../../../shared/templates/usecase.dart';
import '../repositories/i_profile_repository.dart';

class GetProfileUsecase implements Usecase<UserEntity, String> {
  final IProfileRepository _repository;

  GetProfileUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(String userId) async {
    return await _repository.getProfile(userId);
  }
}
