import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/feed_page_result.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/entities/user_search_page_result.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/post_search_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _Social extends SocialRepository {
  final pending = <Completer<Either<Failure, List<PostEntity>>>>[];
  final feedPending = <Completer<Either<Failure, FeedPageResult>>>[];
  final peoplePending = <Completer<Either<Failure, UserSearchPageResult>>>[];
  Completer<Either<Failure, PostMutationState>>? likePending;
  Completer<Either<Failure, SaveMutationState>>? savePending;

  @override
  Future<Either<Failure, FeedPageResult>> getFeed({
    int limit = 20,
    String? cursor,
    int? offset,
    FeedType type = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
  }) {
    final request = Completer<Either<Failure, FeedPageResult>>();
    feedPending.add(request);
    return request.future;
  }

  @override
  Future<Either<Failure, UserSearchPageResult>> searchUsers({
    String? query,
    int limit = 20,
    int offset = 0,
  }) {
    final request = Completer<Either<Failure, UserSearchPageResult>>();
    peoplePending.add(request);
    return request.future;
  }

  @override
  Future<Either<Failure, List<PostEntity>>> searchPosts({
    String? query,
    PostSearchFilter filter = PostSearchFilter.all,
    int limit = 20,
    String? cursor,
  }) {
    final request = Completer<Either<Failure, List<PostEntity>>>();
    pending.add(request);
    return request.future;
  }

  @override
  Future<Either<Failure, PostMutationState>> likePost(String postId) async =>
      likePending == null
      ? const Right(PostMutationState(active: true, count: 1))
      : likePending!.future;

  @override
  Future<Either<Failure, SaveMutationState>> savePost(String postId) async =>
      savePending == null
      ? const Right(SaveMutationState(active: true))
      : savePending!.future;
}

PostEntity _post() => PostEntity(
  id: 'private-post',
  userId: 'owner',
  createdAt: DateTime.utc(2026, 9, 26),
  user: const UserEntity(id: 'owner'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'remember_me': 'false'});
  });

  test(
    'logout discards the previous account social results and interaction state',
    () async {
      final repository = _Social();
      final container = ProviderContainer(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final post = _post();
      container.read(feedProvider.notifier).addPost(post);
      final searching = container
          .read(postSearchProvider.notifier)
          .search(query: 'private', refresh: true);
      repository.pending.single.complete(Right([post]));
      await searching;
      await container
          .read(likesProvider.notifier)
          .toggleLike(post.id, initialIsLiked: false, initialCount: 0);
      await container
          .read(savesProvider.notifier)
          .toggleSave(post.id, initialIsSaved: false);
      expect(container.read(postSearchProvider).posts, hasLength(1));

      await container.read(authControllerProvider.notifier).forceLogout();

      expect(container.read(feedProvider).posts, isEmpty);
      expect(container.read(postSearchProvider).posts, isEmpty);
      expect(container.read(likesProvider).likedOverrides, isEmpty);
      expect(container.read(savesProvider).savedOverrides, isEmpty);
    },
  );

  test('a pending search cannot restore old results after logout', () async {
    final repository = _Social();
    final container = ProviderContainer(
      overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final pending = container
        .read(postSearchProvider.notifier)
        .search(query: 'private', refresh: true);
    await container.read(authControllerProvider.notifier).forceLogout();
    repository.pending.single.complete(Right([_post()]));
    await pending;

    expect(container.read(postSearchProvider).posts, isEmpty);
  });

  test('a pending feed cannot restore old results after logout', () async {
    final repository = _Social();
    final container = ProviderContainer(
      overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final pending = container
        .read(feedProvider.notifier)
        .loadFeed(refresh: true);
    await container.read(authControllerProvider.notifier).forceLogout();
    repository.feedPending.single.complete(
      Right(FeedPageResult(posts: [_post()], hasMore: false)),
    );
    await pending;

    expect(container.read(feedProvider).posts, isEmpty);
  });

  test(
    'pending likes and saves cannot restore old account overrides',
    () async {
      final repository = _Social()
        ..likePending = Completer<Either<Failure, PostMutationState>>()
        ..savePending = Completer<Either<Failure, SaveMutationState>>();
      final container = ProviderContainer(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final liking = container
          .read(likesProvider.notifier)
          .toggleLike('private-post', initialIsLiked: false, initialCount: 0);
      final saving = container
          .read(savesProvider.notifier)
          .toggleSave('private-post', initialIsSaved: false);
      await container.read(authControllerProvider.notifier).forceLogout();
      repository.likePending!.complete(
        const Right(PostMutationState(active: true, count: 1)),
      );
      repository.savePending!.complete(
        const Right(SaveMutationState(active: true)),
      );
      await Future.wait([liking, saving]);

      expect(container.read(likesProvider).likedOverrides, isEmpty);
      expect(container.read(savesProvider).savedOverrides, isEmpty);
    },
  );

  test('logout discards a pending personalized people search', () async {
    final repository = _Social();
    final container = ProviderContainer(
      overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final pending = container
        .read(userSearchProvider.notifier)
        .search(query: 'private', refresh: true);
    await container.read(authControllerProvider.notifier).forceLogout();
    repository.peoplePending.single.complete(
      const Right(
        UserSearchPageResult(
          users: [
            UserSearchEntity(id: 'old', displayName: 'Old account suggestion'),
          ],
          hasMore: false,
        ),
      ),
    );
    await pending;

    expect(container.read(userSearchProvider).users, isEmpty);
  });

  test('a newer people search replaces an older in-flight query', () async {
    final repository = _Social();
    final container = ProviderContainer(
      overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final search = container.read(userSearchProvider.notifier);
    final old = search.search(query: 'old', refresh: true);
    final fresh = search.search(query: 'new', refresh: true);
    expect(repository.peoplePending, hasLength(2));
    repository.peoplePending[1].complete(
      const Right(
        UserSearchPageResult(
          users: [UserSearchEntity(id: 'new', displayName: 'New')],
          hasMore: false,
        ),
      ),
    );
    await fresh;
    repository.peoplePending[0].complete(
      const Right(
        UserSearchPageResult(
          users: [UserSearchEntity(id: 'old', displayName: 'Old')],
          hasMore: false,
        ),
      ),
    );
    await old;

    expect(container.read(userSearchProvider).users.map((u) => u.id), ['new']);
  });
}
