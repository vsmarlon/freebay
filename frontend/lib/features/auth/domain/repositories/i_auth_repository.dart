import 'package:dartz/dartz.dart';
import '../../../../shared/errors/failures/failures.dart';
import '../../data/entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, UserEntity>> login(
      String email, String password, bool rememberMe);
  Future<Either<Failure, UserEntity>> register(
      String email, String password, String displayName);
  Future<Either<Failure, UserEntity>> loginAsGuest();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}
