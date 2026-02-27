import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

// Providers
final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository();
});

final getProfileUsecaseProvider =
    Provider((ref) => GetProfileUsecase(ref.watch(profileRepositoryProvider)));

// Provides user profile details
final profileFutureProvider =
    FutureProvider.family<UserEntity, String>((ref, userId) async {
  final usecase = ref.watch(getProfileUsecaseProvider);
  final result = await usecase(userId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (user) => user,
  );
});
