import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/domain/usecases/get_post_details_usecase.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/features/social/social.dart';

part 'post_details_provider.g.dart';

final getPostDetailsUseCaseProvider = Provider((ref) {
  return GetPostDetailsUseCase(ref.watch(socialRepositoryProvider));
});

final getPostCommentsUseCaseProvider = Provider((ref) {
  return GetPostCommentsUseCase(ref.watch(socialRepositoryProvider));
});

class PostDetailsState {
  final bool isLoading;
  final PostEntity? post;
  final List<CommentEntity> comments;
  final String? error;

  PostDetailsState({
    this.isLoading = false,
    this.post,
    this.comments = const [],
    this.error,
  });

  PostDetailsState copyWith({
    bool? isLoading,
    PostEntity? post,
    List<CommentEntity>? comments,
    String? error,
    bool clearError = false,
  }) {
    return PostDetailsState(
      isLoading: isLoading ?? this.isLoading,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class PostDetails extends _$PostDetails {
  GetPostDetailsUseCase get _getPostDetails =>
      ref.read(getPostDetailsUseCaseProvider);
  GetPostCommentsUseCase get _getPostComments =>
      ref.read(getPostCommentsUseCaseProvider);

  @override
  PostDetailsState build(String postId) {
    Future.microtask(_loadData);
    return PostDetailsState(isLoading: true);
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final postResult = await _getPostDetails(postId);
    if (!ref.mounted) return;
    final commentsResult = await _getPostComments(postId);
    if (!ref.mounted) return;

    PostEntity? post;
    String? errorMessage;

    postResult.fold((failure) => errorMessage = failure.message, (data) {
      post = data;
      reconcileSocialPosts(ref, [data]);
    });

    List<CommentEntity> comments = [];
    commentsResult.fold((failure) {
      errorMessage ??= failure.message;
    }, (data) => comments = data);

    state = state.copyWith(
      isLoading: false,
      post: post,
      comments: comments,
      error: errorMessage,
    );
  }

  Future<void> refresh() async {
    await _loadData();
  }

  /// Increment or decrement the post commentsCount locally so UI reflects instantly.
  void incrementCommentCount([int delta = 1]) {
    if (state.post != null) {
      final current = state.post!.commentsCount;
      state = state.copyWith(
        post: state.post!.copyWith(
          commentsCount: (current + delta).clamp(0, 999999999),
        ),
      );
    }
  }

  /// Silently re-fetches only comments without showing a loading state.
  /// Used after posting a comment so the list updates without flashing.
  Future<void> refreshComments() async {
    final commentsResult = await _getPostComments(postId);
    if (!ref.mounted) return;
    commentsResult.fold(
      (_) {}, // silently ignore errors — existing comments stay visible
      (data) => state = state.copyWith(comments: data),
    );
  }
}
