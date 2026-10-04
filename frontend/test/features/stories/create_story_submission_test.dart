import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/stories/stories.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _FakeStoriesRepository extends StoriesRepository {
  int createCalls = 0;
  final responses = <Completer<Either<Failure, StoryEntity>>>[];

  @override
  Future<Either<Failure, StoryEntity>> createStory(
    String imagePath, {
    String? caption,
    List<StoryTextBlockEntity> textBlocks = const [],
    StoryAudience audience = StoryAudience.everyone,
  }) {
    createCalls++;
    final response = Completer<Either<Failure, StoryEntity>>();
    responses.add(response);
    return response.future;
  }
}

StoryEntity _story(String userId) => StoryEntity(
  id: 'story-1',
  userId: userId,
  imageUrl: '/stories/story-1.jpg',
  expiresAt: DateTime.utc(2026, 9, 15),
  createdAt: DateTime.utc(2026, 9, 14),
  user: const StoryUserEntity(id: 'user-1', displayName: 'User'),
);

void main() {
  test('ignores a concurrent submission while the first is pending', () async {
    final repository = _FakeStoriesRepository();
    final coordinator = StorySubmissionCoordinator();
    final first = coordinator.submit(
      repository: repository,
      imagePath: 'story.jpg',
      invalidateGlobalStories: () {},
      invalidateUserStories: (_) {},
    );
    final second = coordinator.submit(
      repository: repository,
      imagePath: 'story.jpg',
      invalidateGlobalStories: () {},
      invalidateUserStories: (_) {},
    );

    expect(await second, isNull);
    expect(repository.createCalls, 1);
    repository.responses[0].complete(Right(_story('user-1')));
    await first;
  });

  test(
    'invalidates both story providers once using the returned user id',
    () async {
      final repository = _FakeStoriesRepository();
      final coordinator = StorySubmissionCoordinator();
      var globalInvalidations = 0;
      final userInvalidations = <String>[];

      final submission = coordinator.submit(
        repository: repository,
        imagePath: 'story.jpg',
        invalidateGlobalStories: () => globalInvalidations++,
        invalidateUserStories: userInvalidations.add,
      );
      expect(globalInvalidations, 0);
      expect(userInvalidations, isEmpty);
      repository.responses[0].complete(Right(_story('canonical-user')));

      expect(await submission, isNotNull);
      expect(repository.createCalls, 1);
      expect(globalInvalidations, 1);
      expect(userInvalidations, ['canonical-user']);
    },
  );

  test('surfaces failure without invalidating and allows one retry', () async {
    final repository = _FakeStoriesRepository();
    final coordinator = StorySubmissionCoordinator();
    var globalInvalidations = 0;
    final userInvalidations = <String>[];

    final failed = coordinator.submit(
      repository: repository,
      imagePath: 'story.jpg',
      invalidateGlobalStories: () => globalInvalidations++,
      invalidateUserStories: userInvalidations.add,
    );
    repository.responses[0].complete(const Left(ServerFailure('offline')));
    final failureResult = await failed;

    expect(failureResult?.fold((_) => true, (_) => false), true);
    expect(globalInvalidations, 0);
    expect(userInvalidations, isEmpty);

    final retry = coordinator.submit(
      repository: repository,
      imagePath: 'story.jpg',
      invalidateGlobalStories: () => globalInvalidations++,
      invalidateUserStories: userInvalidations.add,
    );
    repository.responses[1].complete(Right(_story('retry-user')));

    expect((await retry)?.fold((_) => false, (_) => true), true);
    expect(repository.createCalls, 2);
  });
}
