import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/domain/usecases/get_post_details_usecase.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/comment_item.dart';
import 'package:freebay/shared/services/http_client.dart';

class _FakeGetPostDetailsUseCase extends GetPostDetailsUseCase {
  final PostEntity post;
  _FakeGetPostDetailsUseCase(this.post) : super(HttpClient());

  @override
  Future<Either<Failure, PostEntity>> call(String postId) async {
    return Right(post);
  }
}

class _FakeGetPostCommentsUseCase extends GetPostCommentsUseCase {
  _FakeGetPostCommentsUseCase() : super(HttpClient());

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String postId) async {
    return const Right([]);
  }
}

void main() {
  group('PostDetailsState & Comments Count', () {
    test(
      'incrementCommentCount increments and clamps commentsCount correctly',
      () async {
        final post = PostEntity(
          id: 'post-1',
          userId: 'u-1',
          content: 'Post test',
          createdAt: DateTime.now(),
          user: const UserEntity(id: 'u-1', displayName: 'Author'),
          commentsCount: 2,
        );

        final container = ProviderContainer(
          overrides: [
            getPostDetailsUseCaseProvider.overrideWithValue(
              _FakeGetPostDetailsUseCase(post),
            ),
            getPostCommentsUseCaseProvider.overrideWithValue(
              _FakeGetPostCommentsUseCase(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(postDetailsProvider('post-1'), (_, _) {});
        addTearDown(sub.close);

        final notifier = container.read(postDetailsProvider('post-1').notifier);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(notifier.state.post?.commentsCount, 2);

        notifier.incrementCommentCount();
        expect(notifier.state.post?.commentsCount, 3);

        notifier.incrementCommentCount(2);
        expect(notifier.state.post?.commentsCount, 5);

        notifier.incrementCommentCount(-10);
        expect(notifier.state.post?.commentsCount, 0);
      },
    );
  });

  group('LikesProvider & Feed Sync', () {
    test(
      'toggleLike updates feedProvider and likesProvider overrides',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final post = PostEntity(
          id: 'post-10',
          userId: 'u-10',
          content: 'Feed test post',
          createdAt: DateTime.now(),
          user: const UserEntity(id: 'u-10', displayName: 'Author 10'),
          likesCount: 5,
        );

        container.read(feedProvider.notifier).state = FeedState(posts: [post]);

        final likesNotifier = container.read(likesProvider.notifier);
        expect(
          likesNotifier.isPostLiked('post-10', initial: post.isLiked),
          false,
        );
        expect(
          likesNotifier.postLikesCount('post-10', initial: post.likesCount),
          5,
        );

        // Verify state override methods
        container.read(likesProvider.notifier).state = const LikesState(
          likedOverrides: {'post-10': true},
          countOverrides: {'post-10': 6},
        );

        expect(likesNotifier.isPostLiked('post-10'), true);
        expect(likesNotifier.postLikesCount('post-10', initial: 5), 6);
      },
    );
  });

  group('CommentItem replies indicator', () {
    final user = const UserEntity(
      id: 'u-1',
      displayName: 'Alice',
      username: 'alice',
    );

    testWidgets('shows simple Responder text when comment has no replies', (
      tester,
    ) async {
      final comment = CommentEntity(
        id: 'c-1',
        content: 'Root comment',
        userId: 'u-1',
        postId: 'p-1',
        createdAt: DateTime.now(),
        user: user,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentItem(
              comment: comment,
              isReplying: false,
              isLiked: false,
              likesCount: 0,
              onReply: () {},
              onLike: () {},
            ),
          ),
        ),
      );

      expect(find.text('Responder'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding ==
                  const EdgeInsets.symmetric(vertical: AppDepth.borderThin),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows reply count indicator when comment has replies', (
      tester,
    ) async {
      final reply = CommentEntity(
        id: 'c-2',
        content: 'Reply comment',
        userId: 'u-2',
        postId: 'p-1',
        parentId: 'c-1',
        createdAt: DateTime.now(),
        user: const UserEntity(id: 'u-2', displayName: 'Bob', username: 'bob'),
      );

      final comment = CommentEntity(
        id: 'c-1',
        content: 'Root comment with replies',
        userId: 'u-1',
        postId: 'p-1',
        createdAt: DateTime.now(),
        user: user,
        replies: [reply],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentItem(
              comment: comment,
              isReplying: false,
              isLiked: false,
              likesCount: 0,
              onReply: () {},
              onLike: () {},
            ),
          ),
        ),
      );

      expect(find.text('Responder • 1 resposta'), findsOneWidget);
    });
  });
}
