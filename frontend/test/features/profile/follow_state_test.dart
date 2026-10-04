import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/profile/data/services/follow_service.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/entities/feed_page_result.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _FakeFollowService extends FollowService {
  Completer<Either<Failure, FollowResponse>>? pendingFollow;
  final List<Completer<Either<Failure, FollowStatusResponse>>> pendingStatuses =
      [];
  final List<String> statusUserIds = [];
  int statusCalls = 0;
  Either<Failure, FollowResponse>? followResult;
  Either<Failure, FollowResponse>? unfollowResult;
  int followCalls = 0;
  int unfollowCalls = 0;

  @override
  Future<Either<Failure, FollowStatusResponse>> getFollowStatus(
    String userId, {
    CancelToken? cancelToken,
  }) {
    statusUserIds.add(userId);
    return pendingStatuses[statusCalls++].future;
  }

  @override
  Future<Either<Failure, FollowResponse>> follow(String userId) async {
    followCalls++;
    if (pendingFollow != null) return pendingFollow!.future;
    return followResult ??
        const Right(
          FollowResponse(
            following: true,
            followersCount: 42,
            followingCount: 10,
          ),
        );
  }

  @override
  Future<Either<Failure, FollowResponse>> unfollow(String userId) async {
    unfollowCalls++;
    return unfollowResult ??
        const Right(
          FollowResponse(
            following: false,
            followersCount: 41,
            followingCount: 10,
          ),
        );
  }
}

class _FakeSocialRepository extends SocialRepository {
  int suggestionsCalls = 0;
  FeedPageResult? feedResult;

  @override
  Future<Either<Failure, FeedPageResult>> getFeed({
    int limit = 20,
    String? cursor,
    int? offset,
    FeedType type = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
  }) async => Right(
    feedResult ??
        FeedPageResult(
          posts: [
            PostEntity(
              id: 'following-post',
              userId: 'user-abc',
              createdAt: DateTime.utc(2026, 9, 12),
              user: const UserEntity(id: 'user-abc'),
            ),
          ],
          hasMore: false,
        ),
  );

  @override
  Future<Either<Failure, List<UserSearchEntity>>> getSuggestions({
    int limit = 10,
  }) async {
    suggestionsCalls++;
    return const Right([]);
  }
}

class _SwitchableAuthController extends AuthController {
  _SwitchableAuthController(this._user);

  final UserEntity? _user;

  @override
  AsyncValue<UserEntity?> build() => AsyncValue.data(_user);

  void switchUser(UserEntity? user) => state = AsyncValue.data(user);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FollowStateNotifier & followStatusProvider', () {
    late _FakeFollowService fakeFollowService;
    late _FakeSocialRepository fakeSocialRepository;
    late ProviderContainer container;

    setUp(() {
      fakeFollowService = _FakeFollowService();
      fakeSocialRepository = _FakeSocialRepository();
      container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'me-user-id')),
          ),
          followServiceProvider.overrideWithValue(fakeFollowService),
          socialRepositoryProvider.overrideWithValue(fakeSocialRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'optimistically updates follow state and confirms with server',
      () async {
        const targetUserId = 'user-abc';

        // Seed initial state: not following, 10 followers
        container
            .read(followStateProvider.notifier)
            .seedStatus(
              targetUserId,
              const FollowStatusResponse(
                isFollowing: false,
                followersCount: 10,
                followingCount: 5,
              ),
            );

        final statusBefore = await container.read(
          followStatusProvider(targetUserId).future,
        );
        expect(statusBefore?.isFollowing, isFalse);
        expect(statusBefore?.followersCount, equals(10));

        // Toggle follow
        fakeFollowService.followResult = const Right(
          FollowResponse(
            following: true,
            followersCount: 11,
            followingCount: 5,
          ),
        );

        final success = await container
            .read(followStateProvider.notifier)
            .toggleFollow(targetUserId);

        expect(success, isTrue);
        expect(fakeFollowService.followCalls, equals(1));

        final statusAfter = await container.read(
          followStatusProvider(targetUserId).future,
        );
        expect(statusAfter?.isFollowing, isTrue);
        expect(statusAfter?.followersCount, equals(11));
      },
    );

    test('rolls back optimistic state on server failure', () async {
      const targetUserId = 'user-err';

      container
          .read(followStateProvider.notifier)
          .seedStatus(
            targetUserId,
            const FollowStatusResponse(
              isFollowing: false,
              followersCount: 5,
              followingCount: 2,
            ),
          );

      fakeFollowService.followResult = const Left(
        ServerFailure('Connection error'),
      );

      final success = await container
          .read(followStateProvider.notifier)
          .toggleFollow(targetUserId);

      expect(success, isFalse);
      final statusAfter = await container.read(
        followStatusProvider(targetUserId).future,
      );
      expect(statusAfter?.isFollowing, isFalse);
      expect(statusAfter?.followersCount, equals(5));
    });

    test(
      'ignores a duplicate follow tap while the request is pending',
      () async {
        final response = Completer<Either<Failure, FollowResponse>>();
        fakeFollowService.pendingFollow = response;
        final notifier = container.read(followStateProvider.notifier);

        final taps = List.generate(
          5,
          (_) => notifier.toggleFollow('slow-user'),
        );
        expect(fakeFollowService.followCalls, 1);
        response.complete(
          const Right(
            FollowResponse(
              following: true,
              followersCount: 1,
              followingCount: 1,
            ),
          ),
        );
        expect(await Future.wait(taps), [true, false, false, false, false]);
        expect(notifier.getStatus('slow-user')?.isFollowing, isTrue);
      },
    );

    test(
      'resets following feed after a successful relationship change',
      () async {
        fakeSocialRepository.feedResult = FeedPageResult(
          posts: [
            PostEntity(
              id: 'following-post',
              userId: 'user-abc',
              createdAt: DateTime.utc(2026, 9, 12),
              user: const UserEntity(id: 'user-abc'),
            ),
          ],
          hasMore: true,
          nextCursor: 'following-cursor',
        );
        await container
            .read(feedProvider.notifier)
            .loadFeed(refresh: true, feedType: FeedType.following);
        expect(container.read(feedProvider).posts, isNotEmpty);
        expect(container.read(feedProvider).cursor, 'following-cursor');

        container
            .read(followStateProvider.notifier)
            .seedStatus(
              'user-abc',
              const FollowStatusResponse(
                isFollowing: false,
                followersCount: 1,
                followingCount: 1,
              ),
            );
        fakeFollowService.followResult = const Left(ServerFailure('offline'));
        final failedFollow = await container
            .read(followStateProvider.notifier)
            .toggleFollow('user-abc');

        expect(failedFollow, isFalse);
        expect(container.read(feedProvider).posts, isNotEmpty);
        expect(container.read(feedProvider).cursor, 'following-cursor');

        fakeFollowService.followResult = null;
        final success = await container
            .read(followStateProvider.notifier)
            .toggleFollow('user-abc');

        expect(success, isTrue);
        expect(container.read(feedProvider).posts, isEmpty);

        await container
            .read(feedProvider.notifier)
            .loadFeed(refresh: true, feedType: FeedType.following);
        fakeFollowService.unfollowResult = const Left(ServerFailure('offline'));
        final failedUnfollow = await container
            .read(followStateProvider.notifier)
            .toggleFollow('user-abc');

        expect(failedUnfollow, isFalse);
        expect(container.read(feedProvider).posts, isNotEmpty);
        expect(container.read(feedProvider).cursor, 'following-cursor');

        fakeFollowService.unfollowResult = null;
        final unfollowed = await container
            .read(followStateProvider.notifier)
            .toggleFollow('user-abc');

        expect(unfollowed, isTrue);
        expect(container.read(feedProvider).posts, isEmpty);
      },
    );

    test(
      'invalidating suggestionsProvider after follow does not throw LateInitializationError',
      () async {
        // Initialize suggestions
        final initialSuggestions = container.read(suggestionsProvider);
        expect(initialSuggestions.isLoading, isFalse);

        // Invalidate multiple times (which previously crashed due to late final _repository)
        container.invalidate(suggestionsProvider);
        final refreshedSuggestions = container.read(suggestionsProvider);
        expect(refreshedSuggestions.isLoading, isFalse);

        container.invalidate(suggestionsProvider);
        final reRefreshedSuggestions = container.read(suggestionsProvider);
        expect(reRefreshedSuggestions.isLoading, isFalse);
      },
    );

    test('discards a pending follow when the account changes', () async {
      final authController = _SwitchableAuthController(
        testUser(id: 'first-account'),
      );
      final service = _FakeFollowService()
        ..pendingFollow = Completer<Either<Failure, FollowResponse>>();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => authController),
          followServiceProvider.overrideWithValue(service),
          socialRepositoryProvider.overrideWithValue(_FakeSocialRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(followStateProvider.notifier);
      final pending = notifier.toggleFollow('target-user');
      expect(container.read(followsInFlightProvider), contains('target-user'));

      authController.switchUser(testUser(id: 'second-account'));
      await container.pump();
      expect(container.read(followsInFlightProvider), isEmpty);
      expect(notifier.getStatus('target-user'), isNull);

      service.pendingFollow!.complete(
        const Right(
          FollowResponse(following: true, followersCount: 1, followingCount: 1),
        ),
      );
      expect(await pending, isFalse);
      expect(notifier.getStatus('target-user'), isNull);
      expect(container.read(followsInFlightProvider), isEmpty);
    });

    test('does not seed a status after its account session changes', () async {
      final authController = _SwitchableAuthController(
        testUser(id: 'first-account'),
      );
      final service = _FakeFollowService()
        ..pendingStatuses.addAll([
          Completer<Either<Failure, FollowStatusResponse>>(),
          Completer<Either<Failure, FollowStatusResponse>>(),
        ]);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => authController),
          followServiceProvider.overrideWithValue(service),
          socialRepositoryProvider.overrideWithValue(_FakeSocialRepository()),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        followStatusProvider('target-user'),
        (_, _) {},
      );
      addTearDown(subscription.close);
      final firstStatusFuture = container.read(
        followStatusProvider('target-user').future,
      );
      const firstStatus = FollowStatusResponse(
        isFollowing: true,
        followersCount: 17,
        followingCount: 4,
      );
      service.pendingStatuses[0].complete(const Right(firstStatus));
      final accountSwitch = Future<void>.microtask(
        () => authController.switchUser(testUser(id: 'second-account')),
      );

      expect(await firstStatusFuture, firstStatus);
      await accountSwitch;
      await container.pump();
      expect(
        container.read(authControllerProvider).value?.id,
        'second-account',
      );
      expect(container.read(followStateProvider), isEmpty);
      expect(service.statusCalls, 2);
      expect(service.statusUserIds, ['target-user', 'target-user']);
      expect(container.read(followStateProvider), isEmpty);

      const secondStatus = FollowStatusResponse(
        isFollowing: false,
        followersCount: 29,
        followingCount: 8,
      );
      service.pendingStatuses[1].complete(const Right(secondStatus));
      expect(
        await container.read(followStatusProvider('target-user').future),
        secondStatus,
      );
      await container.pump();
      expect(container.read(followStateProvider)['target-user'], secondStatus);
    });
  });
}
