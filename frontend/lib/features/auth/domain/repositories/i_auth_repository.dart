import 'package:dartz/dartz.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, UserEntity>> login(
      String email, String password, bool rememberMe);
  Future<Either<Failure, UserEntity>> register(
      String email, String password, String displayName);
  Future<Either<Failure, UserEntity>> loginAsGuest();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, void>> requestPasswordRecovery(String email);
  Future<Either<Failure, bool>> verifyPasswordRecoveryCode(String email, String code);
  Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword);
}
