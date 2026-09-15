import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';

enum FollowListKind { followers, following }

class FollowListNotifier extends StateNotifier<AsyncValue<FollowListResponse>> {
  FollowListNotifier(this._ref, this.userId, this.kind)
    : super(const AsyncValue.loading()) {
    loadMore();
  }

  final Ref _ref;
  final String userId;
  final FollowListKind kind;
  bool _loading = false;

  Future<void> loadMore({bool refresh = false}) async {
    if (_loading) return;
    final current = state.value;
    if (!refresh && current != null && current.users.length >= current.total) {
      return;
    }
    _loading = true;
    if (refresh || current == null) state = const AsyncValue.loading();
    try {
      final repository = _ref.read(profileRepositoryProvider);
      final offset = refresh ? 0 : current?.users.length ?? 0;
      final result = kind == FollowListKind.followers
          ? await repository.getFollowers(userId, offset: offset)
          : await repository.getFollowing(userId, offset: offset);
      result.fold(
        (failure) => state = AsyncValue.error(failure, StackTrace.current),
        (page) {
          final previous = refresh
              ? const <UserBrief>[]
              : current?.users ?? const <UserBrief>[];
          final ids = previous.map((user) => user.id).toSet();
          final users = [
            ...previous,
            ...page.users.where((user) => ids.add(user.id)),
          ];
          state = AsyncValue.data(
            FollowListResponse(
              users: users,
              total: page.total,
              limit: page.limit,
              offset: users.length,
            ),
          );
        },
      );
    } finally {
      _loading = false;
    }
  }
}

final followersListProvider =
    StateNotifierProvider.family<
      FollowListNotifier,
      AsyncValue<FollowListResponse>,
      String
    >((ref, userId) {
      return FollowListNotifier(ref, userId, FollowListKind.followers);
    });

final followingListProvider =
    StateNotifierProvider.family<
      FollowListNotifier,
      AsyncValue<FollowListResponse>,
      String
    >((ref, userId) {
      return FollowListNotifier(ref, userId, FollowListKind.following);
    });

final followingProvider = FutureProvider.family<List<FollowerEntity>, String>((
  ref,
  userId,
) async {
  final result = await ref.read(profileRepositoryProvider).getFollowing(userId);
  return result.fold(
    (failure) => throw failure,
    (page) => page.users
        .map(
          (user) => FollowerEntity(
            id: user.id,
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            isVerified: user.isVerified,
          ),
        )
        .toList(),
  );
});
