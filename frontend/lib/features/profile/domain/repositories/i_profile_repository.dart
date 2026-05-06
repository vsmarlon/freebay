import 'package:dartz/dartz.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';

abstract class IProfileRepository {
  Future<Either<Failure, UserEntity>> getProfile(String userId);
  Future<Either<Failure, UserStatsEntity>> getProfileStats();
  Future<Either<Failure, List<FollowerEntity>>> getFollowers(String userId);
  Future<Either<Failure, List<FollowerEntity>>> getFollowing(String userId);
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? bio,
    String? city,
    String? state,
  });
}
