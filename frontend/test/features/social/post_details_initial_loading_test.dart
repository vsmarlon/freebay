import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/auth.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/domain/usecases/get_post_details_usecase.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import '../../support/auth_test_doubles.dart';

class _PendingPostDetailsUseCase extends GetPostDetailsUseCase {
  Completer<Either<Failure, PostEntity>> result = Completer();

  _PendingPostDetailsUseCase() : super(SocialRepository());

  @override
  Future<Either<Failure, PostEntity>> call(String postId) => result.future;
}

class _SuccessfulPostCommentsUseCase extends GetPostCommentsUseCase {
  _SuccessfulPostCommentsUseCase() : super(SocialRepository());
  Completer<Either<Failure, List<CommentEntity>>>? pending;

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String postId) async =>
      pending?.future ?? const Right<Failure, List<CommentEntity>>([]);
}

void main() {
  test(
    'private revalidation conceals state and rejects late comments on failure',
    () async {
      final getPostDetails = _PendingPostDetailsUseCase();
      final getComments = _SuccessfulPostCommentsUseCase();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => TestAuthController(null)),
          getPostDetailsUseCaseProvider.overrideWithValue(getPostDetails),
          getPostCommentsUseCaseProvider.overrideWithValue(getComments),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        postDetailsProvider('post-1'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      expect(container.read(postDetailsProvider('post-1')).isLoading, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(postDetailsProvider('post-1')).isLoading, isTrue);

      getPostDetails.result.complete(
        Right(
          PostEntity(
            id: 'post-1',
            userId: 'user-1',
            content: 'Post',
            audience: PostAudience.closeFriends,
            createdAt: DateTime(2026),
            user: const UserEntity(id: 'user-1', displayName: 'Author'),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(postDetailsProvider('post-1'));
      expect(state.isLoading, isFalse);
      expect(state.post?.id, 'post-1');
      expect(state.error, isNull);

      getComments.pending = Completer();
      final notifier = container.read(postDetailsProvider('post-1').notifier);
      final pendingComments = notifier.refreshComments();
      getPostDetails.result = Completer();
      final revalidation = notifier.refresh();
      expect(container.read(postDetailsProvider('post-1')).post, isNull);
      expect(container.read(postDetailsProvider('post-1')).comments, isEmpty);
      getPostDetails.result.complete(
        const Left(ServerFailure('access revoked')),
      );
      await revalidation;
      getComments.pending!.complete(
        Right([
          CommentEntity(
            id: 'late-private-reply',
            content: 'private',
            userId: 'user-1',
            postId: 'post-1',
            createdAt: DateTime(2026),
          ),
        ]),
      );
      await pendingComments;
      final revoked = container.read(postDetailsProvider('post-1'));
      expect(revoked.post, isNull);
      expect(revoked.comments, isEmpty);
      expect(revoked.error, 'access revoked');
    },
  );
}
