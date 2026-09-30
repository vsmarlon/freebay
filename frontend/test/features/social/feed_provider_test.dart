import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/feed_page_result.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _FakeSocialRepository extends SocialRepository {
  final List<Completer<Either<Failure, FeedPageResult>>> requests = [];
  final List<String?> cursors = [];
  final List<int?> offsets = [];

  @override
  Future<Either<Failure, FeedPageResult>> getFeed({
    int limit = 20,
    String? cursor,
    int? offset,
    FeedType type = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
  }) {
    cursors.add(cursor);
    offsets.add(offset);
    final request = Completer<Either<Failure, FeedPageResult>>();
    requests.add(request);
    return request.future;
  }
}

PostEntity _post(String id) => PostEntity(
  id: id,
  userId: 'author-$id',
  createdAt: DateTime.utc(2026, 9, 12),
  user: UserEntity(id: 'author-$id'),
);

void main() {
  test('Explore appends with the server cursor instead of an offset', () async {
    final repository = _FakeSocialRepository();
    final container = ProviderContainer(
      overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final feed = container.read(feedProvider.notifier);

    final first = feed.loadFeed(refresh: true);
    repository.requests[0].complete(
      Right(
        FeedPageResult(
          posts: [_post('first')],
          hasMore: true,
          nextCursor: 'explore-1',
        ),
      ),
    );
    await first;
    final second = feed.loadFeed();
    expect(repository.cursors, [null, 'explore-1']);
    expect(repository.offsets, [null, null]);
    repository.requests[1].complete(
      Right(FeedPageResult(posts: [_post('second')], hasMore: false)),
    );
    await second;
    expect(container.read(feedProvider).posts.map((post) => post.id), [
      'first',
      'second',
    ]);
  });

  test(
    'scopes requests, ignores stale responses, and deduplicates posts',
    () async {
      final repository = _FakeSocialRepository();
      final container = ProviderContainer(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(feedProvider.notifier);

      final first = notifier.loadFeed();
      final second = notifier.loadFeed(
        refresh: true,
        feedType: FeedType.following,
        contentFilter: FeedContentFilter.socialOnly,
      );
      repository.requests[1].complete(
        const Right(FeedPageResult(posts: [], hasMore: false)),
      );
      await second;
      repository.requests[0].complete(
        Right(FeedPageResult(posts: [_post('stale')], hasMore: false)),
      );
      await first;

      expect(container.read(feedProvider).posts, isEmpty);

      final page = notifier.loadFeed(
        refresh: true,
        feedType: FeedType.following,
        contentFilter: FeedContentFilter.socialOnly,
      );
      repository.requests[2].complete(
        Right(
          FeedPageResult(
            posts: [_post('same'), _post('same')],
            hasMore: true,
            nextCursor: 'cursor-1',
          ),
        ),
      );
      await page;
      expect(container.read(feedProvider).posts.map((post) => post.id), [
        'same',
      ]);
    },
  );

  test('preserves a failed cursor for retry', () async {
    final repository = _FakeSocialRepository();
    final container = ProviderContainer(
      overrides: [socialRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(feedProvider.notifier);

    final initial = notifier.loadFeed(
      refresh: true,
      feedType: FeedType.following,
    );
    repository.requests[0].complete(
      Right(
        FeedPageResult(
          posts: [_post('one')],
          hasMore: true,
          nextCursor: 'cursor-1',
        ),
      ),
    );
    await initial;

    final failed = notifier.loadFeed(feedType: FeedType.following);
    repository.requests[1].complete(const Left(ServerFailure('offline')));
    await failed;
    expect(container.read(feedProvider).cursor, 'cursor-1');

    final retried = notifier.loadFeed(feedType: FeedType.following);
    expect(repository.cursors, [null, 'cursor-1', 'cursor-1']);
    repository.requests[2].complete(
      const Right(FeedPageResult(posts: [], hasMore: false)),
    );
    await retried;
  });
}
