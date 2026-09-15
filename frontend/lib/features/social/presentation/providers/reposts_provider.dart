import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'reposts_provider.g.dart';

@Riverpod(keepAlive: true)
class Reposts extends _$Reposts {
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  RepostsState build() {
    return const RepostsState();
  }

  Future<bool> toggleRepost(
    String postId, {
    required bool initialIsReposted,
    required int initialCount,
  }) async {
    final currentReposted =
        state.repostedOverrides[postId] ?? initialIsReposted;
    final currentCount = state.countOverrides[postId] ?? initialCount;

    final newIsReposted = !currentReposted;
    final newCount = newIsReposted
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);

    state = state.copyWith(
      repostedOverrides: {...state.repostedOverrides, postId: newIsReposted},
      countOverrides: {...state.countOverrides, postId: newCount},
    );

    try {
      final result = newIsReposted
          ? await _repository.repost(postId)
          : await _repository.unrepost(postId);

      if (result.isLeft) {
        state = state.copyWith(
          repostedOverrides: {
            ...state.repostedOverrides,
            postId: currentReposted,
          },
          countOverrides: {...state.countOverrides, postId: currentCount},
        );
        return false;
      }
      return result.fold((_) => false, (authoritative) {
        state = state.copyWith(
          repostedOverrides: {
            ...state.repostedOverrides,
            postId: authoritative.active,
          },
          countOverrides: {
            ...state.countOverrides,
            postId: authoritative.count,
          },
        );
        return true;
      });
    } catch (e) {
      state = state.copyWith(
        repostedOverrides: {
          ...state.repostedOverrides,
          postId: currentReposted,
        },
        countOverrides: {...state.countOverrides, postId: currentCount},
      );
      return false;
    }
  }
}
