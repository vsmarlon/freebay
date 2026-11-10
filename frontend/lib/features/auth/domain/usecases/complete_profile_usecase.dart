import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class CompleteProfileParams {
  final String username;
  final String? displayName;
  final String? city;
  final String? state;

  CompleteProfileParams({
    required this.username,
    this.displayName,
    this.city,
    this.state,
  });
}

class CompleteProfileUsecase
    implements Usecase<UserEntity, CompleteProfileParams> {
  final AuthRepository _repository;

  CompleteProfileUsecase(this._repository);

  @override
  UsecaseResponse<Failure, UserEntity> call(
    CompleteProfileParams params,
  ) async {
    return await _repository.completeProfile(
      username: params.username,
      displayName: params.displayName,
      city: params.city,
      state: params.state,
    );
  }
}
