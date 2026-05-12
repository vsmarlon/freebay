import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class RepostsState {
  final Map<String, bool> repostedOverrides;
  final Map<String, int> countOverrides;

  const RepostsState({
    this.repostedOverrides = const {},
    this.countOverrides = const {},
  });

  RepostsState copyWith({
    Map<String, bool>? repostedOverrides,
    Map<String, int>? countOverrides,
  }) {
    return RepostsState(
      repostedOverrides: repostedOverrides ?? this.repostedOverrides,
      countOverrides: countOverrides ?? this.countOverrides,
    );
  }

  bool? getRepostedOverride(String postId) => repostedOverrides[postId];
  int? getCountOverride(String postId) => countOverrides[postId];
}

class RepostsNotifier extends StateNotifier<RepostsState> {
  final ISocialRepository _repository;

  RepostsNotifier(this._repository) : super(const RepostsState());

  Future<bool> toggleRepost(String postId, {required bool initialIsReposted, required int initialCount}) async {
    final currentReposted = state.repostedOverrides[postId] ?? initialIsReposted;
    final currentCount = state.countOverrides[postId] ?? initialCount;

    final newIsReposted = !currentReposted;
    final newCount = newIsReposted ? currentCount + 1 : currentCount - 1;

    state = state.copyWith(
      repostedOverrides: {...state.repostedOverrides, postId: newIsReposted},
      countOverrides: {...state.countOverrides, postId: newCount},
    );

    try {
      final result = newIsReposted 
          ? await _repository.repost(postId)
          : await _repository.unrepost(postId);

      if (result.isLeft()) {
        state = state.copyWith(
          repostedOverrides: {...state.repostedOverrides, postId: currentReposted},
          countOverrides: {...state.countOverrides, postId: currentCount},
        );
        return false;
      }
      final newSharesCount = result.fold((_) => newCount, (count) => count);
      state = state.copyWith(
        countOverrides: {...state.countOverrides, postId: newSharesCount},
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        repostedOverrides: {...state.repostedOverrides, postId: currentReposted},
        countOverrides: {...state.countOverrides, postId: currentCount},
      );
      return false;
    }
  }
}

final repostsProvider = StateNotifierProvider<RepostsNotifier, RepostsState>((ref) {
  final repository = ref.read(socialRepositoryProvider);
  return RepostsNotifier(repository);
});
