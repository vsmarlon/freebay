import 'package:dartz/dartz.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import '../../../../shared/errors/failures/failures.dart';
import '../../domain/repositories/i_profile_repository.dart';

class ProfileRepository implements IProfileRepository {
  @override
  Future<Either<Failure, UserEntity>> getProfile(String userId) async {
    try {
      final response = await HttpClient.instance.get('/users/$userId');
      if (response.statusCode == 200 && response.data != null) {
        return Right(UserEntity.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Não foi possível carregar o perfil.'));
      }
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
