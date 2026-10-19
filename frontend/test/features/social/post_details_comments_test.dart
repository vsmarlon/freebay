import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/domain/usecases/get_post_details_usecase.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import 'package:freebay/features/social/presentation/widgets/comment_item.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/pages/post_details_page.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _FakeGetPostDetailsUseCase extends GetPostDetailsUseCase {
  final PostEntity post;
  _FakeGetPostDetailsUseCase(this.post) : super(SocialRepository());

  @override
  Future<Either<Failure, PostEntity>> call(String postId) async {
    return Right(post);
  }
}

class _FakeGetPostCommentsUseCase extends GetPostCommentsUseCase {
  _FakeGetPostCommentsUseCase([this.readComments = _emptyComments])
    : super(SocialRepository());

  final List<CommentEntity> Function() readComments;

  static List<CommentEntity> _emptyComments() => const [];

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String postId) async {
    return Right(readComments());
  }
}

class _RacingGetPostDetailsUseCase extends GetPostDetailsUseCase {
  _RacingGetPostDetailsUseCase(this.firstPost, this.latestPost)
    : super(SocialRepository());

  final Completer<PostEntity> firstPost;
  final PostEntity latestPost;
  var calls = 0;

  @override
  Future<Either<Failure, PostEntity>> call(String postId) {
    calls++;
    return calls == 1
        ? firstPost.future.then<Either<Failure, PostEntity>>(Right.new)
        : Future.value(Right(latestPost));
  }
}

class _ApprovalRepository extends SocialRepository {
  _ApprovalRepository({required this.succeeds});

  final bool succeeds;
  final approvedIds = <String>[];

  @override
  Future<Either<Failure, void>> approveComment(String commentId) async {
    approvedIds.add(commentId);
    return succeeds
        ? const Right(null)
        : const Left(ServerFailure('Approval failed'));
  }
}

PostEntity _post() => PostEntity(
  id: 'post-1',
  userId: 'owner',
  content: 'Post content',
  createdAt: DateTime(2026),
  user: const UserEntity(id: 'owner', displayName: 'Owner'),
  commentsCount: 2,
);

CommentEntity _hiddenComment({
  required String id,
  required String userId,
  String? parentId,
  List<CommentEntity> replies = const [],
}) => CommentEntity(
  id: id,
  content: 'Pending $id',
  userId: userId,
  postId: 'post-1',
  parentId: parentId,
  createdAt: DateTime(2026),
  isHidden: true,
  replies: replies,
);

Future<void> _pumpPostDetails(
  WidgetTester tester, {
  required String viewerId,
  required List<CommentEntity> Function() comments,
  required _ApprovalRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authControllerProvider.overrideWith(
          () => TestAuthController(testUser(id: viewerId)),
        ),
        getPostDetailsUseCaseProvider.overrideWithValue(
          _FakeGetPostDetailsUseCase(_post()),
        ),
        getPostCommentsUseCaseProvider.overrideWithValue(
          _FakeGetPostCommentsUseCase(comments),
        ),
        socialRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PostDetailsPage(postId: 'post-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PostDetailsState & Comments Count', () {
    test(
      'a stale refresh response cannot replace the latest post state',
      () async {
        final firstPost = Completer<PostEntity>();
        final latestPost = _post().copyWith(content: 'latest');
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(() => TestAuthController(null)),
            getPostDetailsUseCaseProvider.overrideWithValue(
              _RacingGetPostDetailsUseCase(firstPost, latestPost),
            ),
            getPostCommentsUseCaseProvider.overrideWithValue(
              _FakeGetPostCommentsUseCase(),
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          postDetailsProvider('post-1'),
          (_, _) {},
        );
        addTearDown(subscription.close);

        await Future<void>.delayed(Duration.zero);
        final notifier = container.read(postDetailsProvider('post-1').notifier);
        await notifier.refresh();
        firstPost.complete(_post().copyWith(content: 'stale'));
        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.post?.content, 'latest');
      },
    );

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
            authControllerProvider.overrideWith(() => TestAuthController(null)),
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
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
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
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
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

  group('PostDetails approval boundary', () {
    testWidgets(
      'owner approval refetches canonical comments; failure stays pending',
      (tester) async {
        final repository = _ApprovalRepository(succeeds: true);
        final comment = _hiddenComment(id: 'pending', userId: 'author');
        await _pumpPostDetails(
          tester,
          viewerId: 'owner',
          comments: () => [
            comment.copyWith(
              isHidden: repository.approvedIds.contains('pending') == false,
            ),
          ],
          repository: repository,
        );

        expect(find.text('Aprovar comentário pendente'), findsOneWidget);
        await tester.tap(find.text('Aprovar comentário pendente'));
        await tester.pumpAndSettle();
        expect(repository.approvedIds, ['pending']);
        expect(_commentTextFinder('Pending pending'), findsOneWidget);
        expect(find.text('Aprovar comentário pendente'), findsNothing);

        final failedRepository = _ApprovalRepository(succeeds: false);
        await _pumpPostDetails(
          tester,
          viewerId: 'owner',
          comments: () => [comment],
          repository: failedRepository,
        );
        await tester.tap(find.text('Aprovar comentário pendente'));
        await tester.pumpAndSettle();
        expect(failedRepository.approvedIds, ['pending']);
        expect(_commentTextFinder('Pending pending'), findsOneWidget);
        expect(find.text('Aprovar comentário pendente'), findsOneWidget);
      },
    );

    testWidgets(
      'author and non-owner cannot approve; hidden-parent descendants are ineligible',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final authorComment = _hiddenComment(
          id: 'author-pending',
          userId: 'author',
        );
        final hiddenChild = _hiddenComment(
          id: 'child',
          userId: 'author',
          parentId: 'hidden-parent',
        );
        final hiddenParent = _hiddenComment(
          id: 'hidden-parent',
          userId: 'other',
          replies: [hiddenChild],
        );
        final repository = _ApprovalRepository(succeeds: true);
        await _pumpPostDetails(
          tester,
          viewerId: 'author',
          comments: () => [authorComment],
          repository: repository,
        );
        expect(_commentTextFinder('Pending author-pending'), findsOneWidget);
        expect(find.text('Aprovar comentário pendente'), findsNothing);

        await _pumpPostDetails(
          tester,
          viewerId: 'visitor',
          comments: () => [hiddenParent],
          repository: repository,
        );
        expect(_commentTextFinder('Pending hidden-parent'), findsNothing);
        expect(find.text('Aprovar comentário pendente'), findsNothing);

        await _pumpPostDetails(
          tester,
          viewerId: 'owner',
          comments: () => [hiddenParent],
          repository: repository,
        );
        expect(_commentTextFinder('Pending hidden-parent'), findsOneWidget);
        expect(find.text('Aprovar comentário pendente'), findsOneWidget);
      },
    );
  });
}

Finder _commentTextFinder(String content) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is CommentItem && widget.comment.content == content,
  ),
  matching: find.byType(BrutalistHighlightedText),
);
