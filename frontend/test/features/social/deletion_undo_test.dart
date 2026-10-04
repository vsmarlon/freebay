import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/data/repositories/stories_repository.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/pages/my_posts_page.dart';
import 'package:freebay/features/stories/presentation/pages/my_stories_page.dart';
import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/stories/presentation/providers/story_highlight_provider.dart';
import 'package:freebay/features/stories/presentation/widgets/story_highlights_section.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/test_users.dart';
import '../../support/auth_test_doubles.dart';

class _DeletionRepository extends SocialRepository {
  final deletedPosts = <String>[];
  final posts = <PostEntity>[];

  @override
  Future<Either<Failure, CursorPage<PostEntity>>> getPostsByUser(
    String userId, {
    int limit = 20,
    String? cursor,
    CancelToken? cancelToken,
  }) async => Right(CursorPage(items: posts, hasMore: false));

  @override
  Future<Either<Failure, void>> deletePost(String id) async {
    deletedPosts.add(id);
    return const Right(null);
  }
}

class _StoryDeletionRepository extends StoriesRepository {
  final deletedStories = <String>[];
  final deletedHighlights = <String>[];

  @override
  Future<Either<Failure, void>> deleteStory(String id) async {
    deletedStories.add(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteStoryHighlight(String id) async {
    deletedHighlights.add(id);
    return const Right(null);
  }
}

void main() {
  testWidgets('undo keeps a confirmed story and sends no delete request', (
    tester,
  ) async {
    final storiesRepository = _StoryDeletionRepository();
    final now = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'owner')),
          ),
          storiesRepositoryProvider.overrideWithValue(storiesRepository),
          userStoriesProvider('owner').overrideWith(
            (ref) async => [
              StoryEntity(
                id: 'story-1',
                userId: 'owner',
                imageUrl: '',
                expiresAt: now.add(const Duration(days: 1)),
                createdAt: now,
                user: const StoryUserEntity(id: 'owner', displayName: 'Owner'),
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MyStoriesPage(userId: 'owner'),
        ),
      ),
    );
    await tester.pump();
    await tester.longPress(
      find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsNothing);
    await tester.tap(find.text('DESFAZER'));
    await tester.pump();
    expect(find.byType(GridView), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(storiesRepository.deletedStories, isEmpty);
  });

  testWidgets('deleting a post waits for the undo deadline before committing', (
    tester,
  ) async {
    final repository = _DeletionRepository();
    repository.posts.add(
      PostEntity(
        id: 'post-1',
        userId: 'owner',
        content: 'Post de teste',
        createdAt: DateTime(2026),
        user: testUser(id: 'owner'),
      ),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.profilePosts,
      routes: [
        GoRoute(
          path: AppRoutes.profilePosts,
          builder: (_, _) => const MyPostsPage(userId: 'owner'),
        ),
        GoRoute(
          path: AppRoutes.postDetails,
          builder: (_, _) => const Scaffold(body: Text('Post aberto')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'owner')),
          ),
          socialRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.longPress(find.text('Post de teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir publicação'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Post de teste'), findsNothing);
    expect(repository.deletedPosts, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('DESFAZER'), findsNothing);
    expect(repository.deletedPosts, ['post-1']);
  });

  testWidgets('undo leaves a highlight intact before the delete request', (
    tester,
  ) async {
    final storiesRepository = _StoryDeletionRepository();
    final now = DateTime.now();
    final highlight = StoryHighlightEntity(
      id: 'highlight-1',
      title: 'Minhas memórias',
      coverUrl: '',
      coverStoryId: 'story-1',
      user: const StoryUserEntity(id: 'owner', displayName: 'Owner'),
      stories: [
        StoryGroupItem(
          id: 'story-1',
          imageUrl: '',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 1)),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storiesRepositoryProvider.overrideWithValue(storiesRepository),
          storyHighlightsProvider(
            'owner',
          ).overrideWith((ref) async => [highlight]),
        ],
        child: const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StoryHighlightsSection(userId: 'owner', isOwnProfile: true),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.longPress(find.text('Minhas memórias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXCLUIR DESTAQUE'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(storiesRepository.deletedHighlights, isEmpty);
    await tester.tap(find.text('DESFAZER'));
    await tester.pump(const Duration(seconds: 5));
    expect(storiesRepository.deletedHighlights, isEmpty);
  });
}
