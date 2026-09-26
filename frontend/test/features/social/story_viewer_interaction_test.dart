import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/pages/story_viewer_page.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/story_page.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _StoryRepository extends SocialRepository {
  @override
  Future<Either<Failure, void>> viewStory(String storyId) async =>
      const Right(null);
}

void main() {
  final now = DateTime.utc(2026, 9, 25);
  final group = StoryGroupEntity(
    user: const StoryUserEntity(id: 'user', displayName: 'Alice'),
    stories: [
      for (final id in ['first', 'second'])
        StoryGroupItem(
          id: id,
          imageUrl: 'https://example.test/$id.png',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 1)),
        ),
    ],
  );

  testWidgets(
    'a photo stays visible for seven seconds and long press pauses it',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            socialRepositoryProvider.overrideWithValue(_StoryRepository()),
          ],
          child: MaterialApp(home: StoryViewerPage(groups: [group])),
        ),
      );
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);

      final gesture = await tester.startGesture(const Offset(700, 400));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('first')), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.byKey(const ValueKey('first')), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(tester.widget<StoryPage>(find.byType(StoryPage)).animationController.isAnimating, isTrue);
    await tester.pump(const Duration(seconds: 6));
    expect(tester.widget<StoryPage>(find.byType(StoryPage)).animationController.value, greaterThan(0.75));
      expect(find.byKey(const ValueKey('first')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byKey(const ValueKey('second')), findsOneWidget);
    },
  );
}
