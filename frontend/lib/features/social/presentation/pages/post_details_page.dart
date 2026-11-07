import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/controllers/post_details_controller.dart';
import 'package:freebay/features/social/presentation/providers/comment_likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/comment_item.dart';
import 'package:freebay/features/social/presentation/widgets/post_details_post_section.dart';
import 'package:freebay/features/social/presentation/widgets/post_details_skeleton.dart';
import 'package:freebay/features/social/presentation/widgets/post_overflow.dart';
import 'package:freebay/features/social/presentation/widgets/mention_suggestions.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PostDetailsPage extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailsPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends ConsumerState<PostDetailsPage> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  bool _isCommentSending = false;
  final Set<String> _approvingCommentIds = {};
  final Set<String> _deletingCommentIds = {};

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_isCommentSending || _commentController.text.characters.length > 280) {
      return;
    }
    setState(() => _isCommentSending = true);
    await ref
        .read(postDetailsControllerProvider(widget.postId))
        .sendComment(context, _commentController);
    if (mounted) {
      setState(() => _isCommentSending = false);
    }
  }

  List<CommentEntity> _flattenComments(List<CommentEntity> roots) {
    final result = <CommentEntity>[];
    void append(List<CommentEntity> comments) {
      for (final comment in comments) {
        result.add(comment);
        append(comment.replies);
      }
    }

    append(roots);
    return result;
  }

  Set<String> _hiddenCommentsWithHiddenParent(List<CommentEntity> comments) {
    final result = <String>{};
    void visit(List<CommentEntity> nodes, bool parentIsHidden) {
      for (final comment in nodes) {
        if (parentIsHidden) result.add(comment.id);
        visit(comment.replies, comment.isHidden);
      }
    }

    visit(comments, false);
    return result;
  }

  List<CommentEntity> _visibleComments(
    List<CommentEntity> comments,
    String? viewerId,
    String postOwnerId,
  ) => comments
      .where(
        (comment) =>
            !comment.isHidden ||
            viewerId == postOwnerId ||
            viewerId == comment.userId,
      )
      .map(
        (comment) => comment.copyWith(
          replies: _visibleComments(comment.replies, viewerId, postOwnerId),
        ),
      )
      .toList();

  Future<void> _approveComment(CommentEntity comment, String ownerId) async {
    if (_approvingCommentIds.contains(comment.id)) return;
    final viewerId = ref.read(authControllerProvider).value?.id;
    if (viewerId != ownerId || !comment.isHidden) return;
    setState(() => _approvingCommentIds.add(comment.id));
    final result = await ref
        .read(socialRepositoryProvider)
        .approveComment(comment.id);
    if (!mounted) return;
    final currentViewerId = ref.read(authControllerProvider).value?.id;
    if (widget.postId != comment.postId || currentViewerId != viewerId) {
      setState(() => _approvingCommentIds.remove(comment.id));
      return;
    }
    await result.fold(
      (failure) async {
        AppSnackbar.error(context, failure.message);
      },
      (_) async {
        await ref.read(postDetailsProvider(widget.postId).notifier).refresh();
      },
    );
    if (mounted) {
      setState(() => _approvingCommentIds.remove(comment.id));
    }
  }

  Future<void> _deleteComment(CommentEntity comment) async {
    if (_deletingCommentIds.contains(comment.id)) return;
    final strings = l10n(context);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(socialRepositoryProvider);
    final notifier = ref.read(postDetailsProvider(widget.postId).notifier);
    await AppDialog.show(
      context: context,
      icon: Icons.delete_outline,
      iconColor: AppColors.error,
      title: strings.feedComment,
      dismissText: strings.commonCancel,
      okText: strings.commonDelete,
      isError: true,
      onOk: () async {
        setState(() => _deletingCommentIds.add(comment.id));
        final result = await repository.deleteComment(comment.id);
        result.fold(
          (failure) {
            if (messenger.mounted) {
              AppSnackbar.errorOnMessenger(messenger, failure.message);
            }
          },
          (_) async {
            notifier.incrementCommentCount(-1);
            await notifier.refreshComments();
          },
        );
        if (mounted) setState(() => _deletingCommentIds.remove(comment.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailsProvider(widget.postId));
    final strings = l10n(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.feedPostTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            BrutalistBreadcrumb(items: context.breadcrumbs),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PostDetailsState state) {
    if (state.isLoading) return const PostDetailsSkeleton();
    if (state.error != null) {
      return EmptyState.error(
        message: state.error,
        onRetry: () =>
            ref.read(postDetailsProvider(widget.postId).notifier).refresh(),
      );
    }
    if (state.post == null) {
      return Center(child: Text(l10n(context).feedPostNotFound));
    }

    final post = state.post!;
    final likes = ref.watch(
      likesProvider.select(
        (state) => (
          isLiked: state.getLikedOverride(post.id),
          count: state.getCountOverride(post.id),
        ),
      ),
    );
    final isSaved = ref.watch(
      savesProvider.select((state) => state.getSavedOverride(post.id)),
    );
    final reposts = ref.watch(
      repostsProvider.select(
        (state) => (
          isReposted: state.getRepostedOverride(post.id),
          count: state.getCountOverride(post.id),
        ),
      ),
    );
    final viewerId = ref.watch(authControllerProvider).value?.id;
    final visibleComments = _visibleComments(
      state.comments,
      viewerId,
      post.user.id,
    );
    final flattenedComments = _flattenComments(visibleComments);
    final hiddenParents = _hiddenCommentsWithHiddenParent(visibleComments);
    return AppRefreshIndicator(
      onRefresh: () =>
          ref.read(postDetailsProvider(widget.postId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PostDetailsPostSection(
              post: post,
              likesCount: likes.count ?? post.likesCount,
              sharesCount: reposts.count ?? post.sharesCount,
              isLiked: likes.isLiked ?? post.isLiked,
              isSaved: isSaved ?? post.isSaved,
              isReposted: reposts.isReposted ?? post.hasReposted,
              onUserTap: () => context.push(AppRoutes.userPath(post.user.id)),
              onLike: () => _toggleLike(post.id, post.isLiked, post.likesCount),
              onSave: () => _toggleSave(post.id, post.isSaved),
              onRepost: () =>
                  _toggleRepost(post.id, post.hasReposted, post.sharesCount),
              onComment: () => FocusScope.of(context).unfocus(),
              onShare: () => _sharePost(context, post.id),
              onQuote: post.isQuote || post.audience != PostAudience.everyone
                  ? null
                  : () => context.push(
                      AppRoutes.createPost,
                      extra: QuoteSource.post(id: post.id, post: post),
                    ),
              onMore: () => showPostOverflowMenu(
                context,
                ref,
                postId: post.id,
                authorId: post.user.id,
                viewerId: viewerId,
                onDeleted: () => context.pop(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n(context).feedComments,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: CommentInput(
                controller: _commentController,
                focusNode: _commentFocus,
                isSending: _isCommentSending,
                onSend: _sendComment,
                suggestions: MentionSuggestions(
                  controller: _commentController,
                  focusNode: _commentFocus,
                ),
              ),
            ),
          ),
          if (visibleComments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.chat_bubble_outline,
                title: l10n(context).feedNoComments,
                subtitle: l10n(context).feedFirstComment,
              ),
            )
          else
            SliverList.builder(
              itemCount: flattenedComments.length,
              itemBuilder: (context, index) => _buildCommentNode(
                context,
                flattenedComments[index],
                post.user.id,
                viewerId,
                hiddenParents,
                post.audience == PostAudience.everyone,
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _toggleLike(String id, bool initial, int count) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      if (mounted) AppSnackbar.warning(context, l10n(context).feedLoginToLike);
      return false;
    }
    final success = await ref
        .read(likesProvider.notifier)
        .toggleLike(id, initialIsLiked: initial, initialCount: count);
    return success;
  }

  Future<bool> _toggleSave(String id, bool initial) async {
    if (ref.read(authControllerProvider).value == null) {
      if (mounted) AppSnackbar.warning(context, l10n(context).feedLoginToSave);
      return false;
    }
    return ref
        .read(savesProvider.notifier)
        .toggleSave(id, initialIsSaved: initial);
  }

  Future<bool> _toggleRepost(String id, bool initial, int count) async {
    if (ref.read(authControllerProvider).value == null) {
      if (mounted) {
        AppSnackbar.warning(context, l10n(context).feedLoginToRepost);
      }
      return false;
    }
    final success = await ref
        .read(repostsProvider.notifier)
        .toggleRepost(id, initialIsReposted: initial, initialCount: count);
    return success;
  }

  Future<void> _sharePost(BuildContext context, String id) async {
    if (ref.read(authControllerProvider).value == null) {
      if (mounted) {
        AppSnackbar.warning(context, l10n(context).feedLoginToShare);
      }
      return;
    }
    final result = await ref.read(socialRepositoryProvider).sharePost(id, null);
    if (!context.mounted) return;
    result.fold(
      (_) => AppSnackbar.error(context, l10n(context).feedShareFailed),
      (_) => AppSnackbar.success(context, l10n(context).feedShareSuccess),
    );
  }

  Widget _buildCommentNode(
    BuildContext context,
    CommentEntity comment,
    String postOwnerId,
    String? viewerId,
    Set<String> hiddenParents,
    bool isPublicPost,
  ) {
    final likes = ref.watch(commentLikesProvider);
    return Column(
      children: [
        CommentItem(
          comment: comment,
          isReplying: false,
          isLiked: likes.getLikedOverride(comment.id) ?? comment.isLiked,
          likesCount: likes.getCountOverride(comment.id) ?? comment.likesCount,
          canApprove:
              viewerId == postOwnerId &&
              comment.isHidden &&
              !hiddenParents.contains(comment.id),
          isApproving: _approvingCommentIds.contains(comment.id),
          onApprove: () => _approveComment(comment, postOwnerId),
          canDelete: viewerId != null && comment.user?.id == viewerId,
          isDeleting: _deletingCommentIds.contains(comment.id),
          onDelete: () => _deleteComment(comment),
          onQuote: comment.isHidden || comment.user == null || !isPublicPost
              ? null
              : () => context.push(
                  AppRoutes.createPost,
                  extra: QuoteSource.comment(
                    id: comment.id,
                    postId: comment.postId,
                    comment: comment,
                  ),
                ),
          onReply: () =>
              context.push(AppRoutes.commentPath(widget.postId, comment.id)),
          onLike: () async {
            if (ref.read(authControllerProvider).value == null) {
              if (context.mounted) {
                AppSnackbar.warning(context, l10n(context).feedLoginToLike);
              }
              return;
            }
            await ref
                .read(commentLikesProvider.notifier)
                .toggleLike(
                  comment.id,
                  initialIsLiked: comment.isLiked,
                  initialCount: comment.likesCount,
                );
          },
          onUserTap: comment.user != null
              ? () => context.push(AppRoutes.userPath(comment.user!.id))
              : null,
        ),
      ],
    );
  }
}
