import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/domain/usecases/get_post_details_usecase.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';

class _PendingPostDetailsUseCase extends GetPostDetailsUseCase {
  final Completer<Either<Failure, PostEntity>> result = Completer();

  _PendingPostDetailsUseCase() : super(SocialRepository());

  @override
  Future<Either<Failure, PostEntity>> call(String postId) => result.future;
}

class _SuccessfulPostCommentsUseCase extends GetPostCommentsUseCase {
  _SuccessfulPostCommentsUseCase() : super(SocialRepository());

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String postId) async =>
      const Right<Failure, List<CommentEntity>>([]);
}

void main() {
  test('starts loading before the post request can complete', () async {
    final getPostDetails = _PendingPostDetailsUseCase();
    final container = ProviderContainer(
      overrides: [
        getPostDetailsUseCaseProvider.overrideWithValue(getPostDetails),
        getPostCommentsUseCaseProvider.overrideWithValue(
          _SuccessfulPostCommentsUseCase(),
        ),
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
  });
}
