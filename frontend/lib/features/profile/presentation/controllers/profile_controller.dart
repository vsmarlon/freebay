import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:freebay/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:freebay/features/profile/data/entities/user_stats_entity.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/profile/presentation/controllers/states/user_posts_state.dart';

part 'profile_controller.g.dart';

@riverpod
class UserPosts extends _$UserPosts {
  @override
  UserPostsState build(String userId) {
    Future.microtask(loadMore);
    return const UserPostsState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    final repository = ref.read(socialRepositoryProvider);
    final result = await repository.getPostsByUser(
      userId,
      cursor: state.cursor,
      limit: 15,
    );

    result.fold((failure) => state = state.copyWith(isLoading: false), (
      newPosts,
    ) {
      final allPosts = [...state.posts, ...newPosts];
      state = state.copyWith(
        posts: allPosts,
        isLoading: false,
        hasMore: newPosts.length >= 15,
        cursor: newPosts.isNotEmpty ? newPosts.last.id : state.cursor,
      );
    });
  }
}

// Providers
final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository();
});

final getProfileUsecaseProvider = Provider(
  (ref) => GetProfileUsecase(ref.watch(profileRepositoryProvider)),
);

// Provides user profile details
final profileFutureProvider = FutureProvider.family<UserEntity, String>((
  ref,
  userId,
) async {
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
