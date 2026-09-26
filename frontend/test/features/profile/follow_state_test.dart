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
  Either<Failure, FollowResponse>? followResult;
  Either<Failure, FollowResponse>? unfollowResult;
  int followCalls = 0;
  int unfollowCalls = 0;

  @override
  Future<Either<Failure, FollowResponse>> follow(String userId) async {
    followCalls++;
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
  });
}
