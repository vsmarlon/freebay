import 'package:dartz/dartz.dart';
import '../../../../shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

abstract class IProfileRepository {
  Future<Either<Failure, UserEntity>> getProfile(String userId);
}
