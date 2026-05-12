import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/domain/usecases/get_post_details_usecase.dart';
import 'package:freebay/shared/services/http_client.dart';

final httpClientProvider = Provider((ref) => HttpClient());

final getPostDetailsUseCaseProvider = Provider((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return GetPostDetailsUseCase(httpClient);
});

final getPostCommentsUseCaseProvider = Provider((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return GetPostCommentsUseCase(httpClient);
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

class PostDetailsNotifier extends StateNotifier<PostDetailsState> {
  final GetPostDetailsUseCase _getPostDetails;
  final GetPostCommentsUseCase _getPostComments;
  final String postId;

  PostDetailsNotifier(
    this._getPostDetails,
    this._getPostComments,
    this.postId,
  ) : super(PostDetailsState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final postResult = await _getPostDetails(postId);
    final commentsResult = await _getPostComments(postId);

    PostEntity? post;
    String? errorMessage;

    postResult.fold(
      (failure) => errorMessage = failure.message,
      (data) => post = data,
    );

    List<CommentEntity> comments = [];
    commentsResult.fold(
      (failure) {
        errorMessage ??= failure.message;
      },
      (data) => comments = data,
    );

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
}

final postDetailsProvider =
    StateNotifierProvider.family<PostDetailsNotifier, PostDetailsState, String>(
        (ref, postId) {
  return PostDetailsNotifier(
    ref.watch(getPostDetailsUseCaseProvider),
    ref.watch(getPostCommentsUseCaseProvider),
    postId,
  );
});
