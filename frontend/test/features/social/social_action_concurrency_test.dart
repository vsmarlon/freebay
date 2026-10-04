import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _SlowSocialRepository extends SocialRepository {
  final likeResponse = Completer<Either<Failure, PostMutationState>>();
  final nextLikeResponse = Completer<Either<Failure, PostMutationState>>();
  final saveResponse = Completer<Either<Failure, SaveMutationState>>();
  final repostResponse = Completer<Either<Failure, PostMutationState>>();
  int likeCalls = 0;
  int saveCalls = 0;
  int repostCalls = 0;

  @override
  Future<Either<Failure, PostMutationState>> likePost(String postId) {
    likeCalls++;
    return (likeCalls == 1 ? likeResponse : nextLikeResponse).future;
  }

  @override
  Future<Either<Failure, SaveMutationState>> savePost(String postId) {
    saveCalls++;
    return saveResponse.future;
  }

  @override
  Future<Either<Failure, PostMutationState>> repost(String postId) {
    repostCalls++;
    return repostResponse.future;
  }
}

void main() {
  test(
    'five rapid taps admit one request for each social action key',
    () async {
      final repository = _SlowSocialRepository();
      final container = ProviderContainer(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final likeNotifier = container.read(likesProvider.notifier);
      final saveNotifier = container.read(savesProvider.notifier);
      final repostNotifier = container.read(repostsProvider.notifier);
      final likes = List.generate(
        5,
        (_) => likeNotifier.toggleLike(
          'post-1',
          initialIsLiked: false,
          initialCount: 0,
        ),
      );
      final saves = List.generate(
        5,
        (_) => saveNotifier.toggleSave('post-1', initialIsSaved: false),
      );
      final reposts = List.generate(
        5,
        (_) => repostNotifier.toggleRepost(
          'post-1',
          initialIsReposted: false,
          initialCount: 0,
        ),
      );

      expect(repository.likeCalls, 1);
      expect(repository.saveCalls, 1);
      expect(repository.repostCalls, 1);
      repository.likeResponse.complete(
        const Right(PostMutationState(active: true, count: 1)),
      );
      repository.saveResponse.complete(
        const Right(SaveMutationState(active: true)),
      );
      repository.repostResponse.complete(
        const Right(PostMutationState(active: true, count: 1)),
      );

      expect(await Future.wait(likes), [true, false, false, false, false]);
      expect(await Future.wait(saves), [true, false, false, false, false]);
      expect(await Future.wait(reposts), [true, false, false, false, false]);
      expect(container.read(likesProvider).likedOverrides['post-1'], isTrue);
      expect(container.read(likesProvider).countOverrides['post-1'], 1);
      expect(container.read(savesProvider).savedOverrides['post-1'], isTrue);
      expect(
        container.read(repostsProvider).repostedOverrides['post-1'],
        isTrue,
      );
      expect(container.read(repostsProvider).countOverrides['post-1'], 1);

      final freshPosts = [
        PostEntity(
          id: 'post-1',
          userId: 'author',
          createdAt: DateTime.utc(2026),
          user: const UserEntity(id: 'author'),
          isLiked: true,
          likesCount: 1,
          isSaved: true,
          hasReposted: true,
          sharesCount: 1,
        ),
      ];
      likeNotifier.reconcilePosts(freshPosts);
      saveNotifier.reconcilePosts(freshPosts);
      repostNotifier.reconcilePosts(freshPosts);
      expect(container.read(likesProvider).likedOverrides, isEmpty);
      expect(container.read(likesProvider).countOverrides, isEmpty);
      expect(container.read(savesProvider).savedOverrides, isEmpty);
      expect(container.read(repostsProvider).repostedOverrides, isEmpty);
      expect(container.read(repostsProvider).countOverrides, isEmpty);
    },
  );

  test(
    'a superseded action failure cannot rollback a new session action',
    () async {
      final repository = _SlowSocialRepository();
      final container = ProviderContainer(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(likesProvider.notifier);

      final oldSession = notifier.toggleLike(
        'post-1',
        initialIsLiked: false,
        initialCount: 0,
      );
      notifier.clear();
      final currentSession = notifier.toggleLike(
        'post-1',
        initialIsLiked: false,
        initialCount: 0,
      );

      repository.likeResponse.complete(const Left(ServerFailure('offline')));
      expect(await oldSession, isFalse);
      expect(notifier.isPostLiked('post-1'), isTrue);
      repository.nextLikeResponse.complete(
        const Right(PostMutationState(active: true, count: 1)),
      );
      expect(await currentSession, isTrue);
      expect(notifier.postLikesCount('post-1'), 1);
    },
  );

  test('a current like failure restores both active state and count', () async {
    final repository = _SlowSocialRepository();
    final container = ProviderContainer(
      overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(likesProvider.notifier);

    final toggle = notifier.toggleLike(
      'post-1',
      initialIsLiked: false,
      initialCount: 7,
    );
    expect(notifier.isPostLiked('post-1'), isTrue);
    expect(notifier.postLikesCount('post-1'), 8);
    repository.likeResponse.complete(const Left(ServerFailure('offline')));

    expect(await toggle, isFalse);
    expect(notifier.isPostLiked('post-1'), isFalse);
    expect(notifier.postLikesCount('post-1', initial: 7), 7);
  });

  test(
    'feed reconciliation cannot invalidate an in-flight like response',
    () async {
      final repository = _SlowSocialRepository();
      final container = ProviderContainer(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(likesProvider.notifier);
      final toggle = notifier.toggleLike(
        'post-1',
        initialIsLiked: false,
        initialCount: 0,
      );
      notifier.reconcilePosts([
        PostEntity(
          id: 'post-1',
          userId: 'author',
          createdAt: DateTime.utc(2026),
          user: const UserEntity(id: 'author'),
          isLiked: true,
          likesCount: 1,
        ),
      ]);
      repository.likeResponse.complete(
        const Right(PostMutationState(active: true, count: 7)),
      );

      expect(await toggle, isTrue);
      expect(notifier.postLikesCount('post-1'), 7);
    },
  );
}
