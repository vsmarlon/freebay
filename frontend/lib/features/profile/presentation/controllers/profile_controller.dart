import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:freebay/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

// Providers
final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository();
});

final getProfileUsecaseProvider =
    Provider((ref) => GetProfileUsecase(ref.watch(profileRepositoryProvider)));

// Provides user profile details
final profileFutureProvider =
    FutureProvider.family<UserEntity, String>((ref, userId) async {
  ref.watch(authControllerProvider);
  final usecase = ref.watch(getProfileUsecaseProvider);
  final result = await usecase(userId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (user) => user,
  );
});

final profileStatsProvider = FutureProvider<UserStatsEntity>((ref) async {
  ref.watch(authControllerProvider);
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getProfileStats();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (stats) => stats,
  );
});
