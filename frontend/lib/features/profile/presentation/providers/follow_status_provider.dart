import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/profile/data/services/follow_service.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

final followServiceProvider = Provider<FollowService>((ref) => FollowService());

/// Single reactive source of truth for follow states and follower counts.
class FollowStateNotifier extends Notifier<Map<String, FollowStatusResponse>> {
  String? _ownerId;
  int _sessionId = 0;
  final Set<String> _inFlight = <String>{};

  @override
  Map<String, FollowStatusResponse> build() {
    final ownerId = ref.watch(
      authControllerProvider.select((auth) => auth.asData?.value?.id),
    );
    if (_ownerId != ownerId) {
      _ownerId = ownerId;
      _sessionId++;
      _inFlight.clear();
    }
    return {};
  }

  void clear() {
    _sessionId++;
    _inFlight.clear();
    state = {};
    ref.read(followsInFlightProvider.notifier).clear();
  }

  FollowStatusResponse? getStatus(String userId) => state[userId];

  void seedStatus(String userId, FollowStatusResponse status) {
    if (state.containsKey(userId)) return;
    state = {...state, userId: status};
  }

  void updateStatus(String userId, FollowStatusResponse status) {
    state = {...state, userId: status};
  }

  /// Toggles follow with optimistic update and server confirmation.
  Future<bool> toggleFollow(
    String userId, {
    int? fallbackFollowersCount,
    int? fallbackFollowingCount,
  }) async {
    if (!_inFlight.add(userId)) return false;
    final sessionId = _sessionId;
    final current = state[userId];
    final wasFollowing = current?.isFollowing ?? false;
    final currentFollowers =
        current?.followersCount ?? fallbackFollowersCount ?? 0;
    final currentFollowing =
        current?.followingCount ?? fallbackFollowingCount ?? 0;

    final targetFollowing = !wasFollowing;
    final optimisticFollowers = targetFollowing
        ? currentFollowers + 1
        : (currentFollowers > 0 ? currentFollowers - 1 : 0);

    // 1. Optimistic update: instantly update state for all listeners
    state = {
      ...state,
      userId: FollowStatusResponse(
        isFollowing: targetFollowing,
        followersCount: optimisticFollowers,
        followingCount: currentFollowing,
      ),
    };

    // 2. Perform network request (tracked so buttons can show progress)
    ref.read(followsInFlightProvider.notifier).mark(userId);
    try {
      final service = ref.read(followServiceProvider);
      final result = targetFollowing
          ? await service.follow(userId)
          : await service.unfollow(userId);
      if (!ref.mounted || sessionId != _sessionId) return false;

      // 3. Handle response
      return result.fold(
        (failure) {
          // Rollback on failure
          if (current != null) {
            state = {...state, userId: current};
          } else {
            final copy = Map<String, FollowStatusResponse>.of(state);
            copy.remove(userId);
            state = copy;
          }
          return false;
        },
        (response) {
          // 4. Update with authoritative server values
          state = {
            ...state,
            userId: FollowStatusResponse(
              isFollowing: response.following,
              followersCount: response.followersCount,
              followingCount: response.followingCount,
            ),
          };

          // 5. Invalidate dependent providers
          ref.invalidate(profileFutureProvider(userId));
          ref.invalidate(profileStatsProvider);
          ref.invalidate(suggestionsProvider);
          ref.read(feedProvider.notifier).resetFollowing();

          return true;
        },
      );
    } catch (_) {
      if (!ref.mounted || sessionId != _sessionId) return false;
      if (current != null) {
        state = {...state, userId: current};
      } else {
        final copy = Map<String, FollowStatusResponse>.of(state)
          ..remove(userId);
        state = copy;
      }
      return false;
    } finally {
      if (sessionId == _sessionId) {
        _inFlight.remove(userId);
        ref.read(followsInFlightProvider.notifier).unmark(userId);
      }
    }
  }

  /// Backward-compatible alias for optimisticToggle
  Future<void> optimisticToggle(
    String userId, {
    required bool currentlyFollowing,
    int? fallbackFollowersCount,
    int? fallbackFollowingCount,
  }) async {
    await toggleFollow(
      userId,
      fallbackFollowersCount: fallbackFollowersCount,
      fallbackFollowingCount: fallbackFollowingCount,
    );
  }
}

final followStateProvider =
    NotifierProvider<FollowStateNotifier, Map<String, FollowStatusResponse>>(
      FollowStateNotifier.new,
    );

/// Ids with a follow/unfollow request in flight (single source for spinners).
class FollowsInFlightNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(authControllerProvider.select((auth) => auth.asData?.value?.id));
    return const {};
  }

  void mark(String userId) => state = {...state, userId};

  void clear() => state = const {};

  void unmark(String userId) {
    if (!state.contains(userId)) return;
    state = state.where((id) => id != userId).toSet();
  }
}

final followsInFlightProvider =
    NotifierProvider<FollowsInFlightNotifier, Set<String>>(
      FollowsInFlightNotifier.new,
    );

final followStatusProvider = FutureProvider.autoDispose
    .family<FollowStatusResponse?, String>((ref, userId) async {
      final authState = ref.watch(authControllerProvider);
      final user = authState.value;

      if (user == null || user.id == userId) {
        return null;
      }

      // Watch the in-memory follow state. Whenever followStateProvider changes for this userId,
      // this provider re-evaluates and notifies all listeners!
      final trackedMap = ref.watch(followStateProvider);
      if (trackedMap.containsKey(userId)) {
        return trackedMap[userId];
      }

      final service = ref.read(followServiceProvider);
      final sessionUserId = user.id;
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      final result = await service.getFollowStatus(
        userId,
        cancelToken: cancelToken,
      );
      if (!ref.mounted ||
          ref.read(authControllerProvider).asData?.value?.id != sessionUserId) {
        return null;
      }

      return result.fold((failure) => null, (status) {
        Future.microtask(() {
          if (!ref.mounted ||
              ref.read(authControllerProvider).asData?.value?.id !=
                  sessionUserId) {
            return;
          }
          ref.read(followStateProvider.notifier).seedStatus(userId, status);
        });
        return status;
      });
    });
