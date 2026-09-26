import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/presentation/controllers/post_details_controller.dart';
import 'package:freebay/features/social/presentation/providers/comment_likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/comment_item.dart';
import 'package:freebay/features/social/presentation/widgets/post_details_comment_tree.dart';
import 'package:freebay/features/social/presentation/widgets/post_details_post_section.dart';
import 'package:freebay/features/social/presentation/widgets/post_details_skeleton.dart';

class PostDetailsPage extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailsPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends ConsumerState<PostDetailsPage> {
  final _commentController = TextEditingController();
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  bool _isCommentSending = false;
  bool _isReplySending = false;
  String? _replyToId;

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final isReply = _replyToId != null;
    if (isReply ? _isReplySending : _isCommentSending) return;
    final controller = isReply ? _replyController : _commentController;
    setState(() => isReply ? _isReplySending = true : _isCommentSending = true);
    final sent = await ref
        .read(postDetailsControllerProvider(widget.postId))
        .sendComment(context, controller, parentId: _replyToId);
    if (sent && mounted) {
      setState(() => _replyToId = null);
      _replyController.clear();
    }
    if (mounted) {
      setState(
        () => isReply ? _isReplySending = false : _isCommentSending = false,
      );
    }
  }

  void _setReplyTo(CommentEntity comment) {
    setState(() => _replyToId = comment.id);
    final handle = comment.user?.username;
    _replyController.text = handle != null && handle.isNotEmpty
        ? '@$handle '
        : '';
    _replyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _replyController.text.length),
    );
    Future.microtask(_replyFocusNode.requestFocus);
  }

  TreeNode<CommentEntity> _buildTree(List<CommentEntity> comments) {
    final root = TreeNode<CommentEntity>.root();
    for (final comment in comments) {
      root.add(_createNode(comment));
    }
    return root;
  }

  TreeNode<CommentEntity> _createNode(CommentEntity comment) {
    final node = TreeNode<CommentEntity>(key: comment.id, data: comment);
    for (final reply in comment.replies) {
      node.add(_createNode(reply));
    }
    return node;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailsProvider(widget.postId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const PageHeader(text: 'POST'),
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
      return const Center(child: Text('Post não encontrado'));
    }

    final post = state.post!;
    final likes = ref.watch(likesProvider);
    final saves = ref.watch(savesProvider);
    final reposts = ref.watch(repostsProvider);
    final tree = _buildTree(state.comments);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(postDetailsProvider(widget.postId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PostDetailsPostSection(
              post: post,
              likesCount: likes.getCountOverride(post.id) ?? post.likesCount,
              sharesCount:
                  reposts.getCountOverride(post.id) ?? post.sharesCount,
              isLiked: likes.getLikedOverride(post.id) ?? post.isLiked,
              isSaved: saves.getSavedOverride(post.id) ?? post.isSaved,
              isReposted:
                  reposts.getRepostedOverride(post.id) ?? post.hasReposted,
              onUserTap: () => context.push(AppRoutes.userPath(post.user.id)),
              onLike: () => _toggleLike(post.id, post.isLiked, post.likesCount),
              onSave: () => _toggleSave(post.id, post.isSaved),
              onRepost: () =>
                  _toggleRepost(post.id, post.hasReposted, post.sharesCount),
              onComment: () => FocusScope.of(context).unfocus(),
              onShare: () => _sharePost(context, post.id),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Comentários',
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
                isSending: _isCommentSending,
                onSend: _sendComment,
              ),
            ),
          ),
          if (state.comments.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'NENHUM COMENTÁRIO',
                subtitle: 'Seja o primeiro a comentar!',
              ),
            )
          else
            SliverToBoxAdapter(
              child: PostDetailsCommentTree(
                tree: tree,
                height: MediaQuery.of(context).size.height * 0.6,
                itemBuilder: _buildCommentNode,
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _toggleLike(String id, bool initial, int count) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      if (mounted) AppSnackbar.warning(context, 'Faça login para curtir');
      return false;
    }
    final success = await ref
        .read(likesProvider.notifier)
        .toggleLike(id, initialIsLiked: initial, initialCount: count);
    if (success) {
      final next = ref.read(likesProvider);
      ref
          .read(feedProvider.notifier)
          .updatePostLike(
            id,
            next.getLikedOverride(id) ?? initial,
            next.getCountOverride(id) ?? count,
          );
    }
    return success;
  }

  Future<bool> _toggleSave(String id, bool initial) async {
    if (ref.read(authControllerProvider).value == null) {
      if (mounted) AppSnackbar.warning(context, 'Faça login para salvar');
      return false;
    }
    return ref
        .read(savesProvider.notifier)
        .toggleSave(id, initialIsSaved: initial);
  }

  Future<bool> _toggleRepost(String id, bool initial, int count) async {
    if (ref.read(authControllerProvider).value == null) {
      if (mounted) AppSnackbar.warning(context, 'Faça login para repostar');
      return false;
    }
    final success = await ref
        .read(repostsProvider.notifier)
        .toggleRepost(id, initialIsReposted: initial, initialCount: count);
    if (success) {
      ref
          .read(feedProvider.notifier)
          .updateSharesCount(
            id,
            ref.read(repostsProvider).getCountOverride(id) ?? count,
          );
    }
    return success;
  }

  Future<void> _sharePost(BuildContext context, String id) async {
    if (ref.read(authControllerProvider).value == null) {
      if (mounted) AppSnackbar.warning(context, 'Faça login para compartilhar');
      return;
    }
    final result = await ref.read(socialRepositoryProvider).sharePost(id, null);
    if (!context.mounted) return;
    result.fold(
      (_) => AppSnackbar.error(context, 'Não foi possível compartilhar'),
      (_) => AppSnackbar.success(context, 'Compartilhado no seu perfil'),
    );
  }

  Widget _buildCommentNode(BuildContext context, CommentEntity comment) {
    final isReplying = _replyToId == comment.id;
    final likes = ref.watch(commentLikesProvider);
    return Column(
      children: [
        CommentItem(
          comment: comment,
          isReplying: isReplying,
          isLiked: likes.getLikedOverride(comment.id) ?? comment.isLiked,
          likesCount: likes.getCountOverride(comment.id) ?? comment.likesCount,
          onReply: () => _setReplyTo(comment),
          onLike: () async {
            if (ref.read(authControllerProvider).value == null) {
              if (context.mounted) {
                AppSnackbar.warning(context, 'Faça login para curtir');
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
        if (isReplying)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: CommentInput(
              controller: _replyController,
              focusNode: _replyFocusNode,
              isSending: _isReplySending,
              onSend: _sendComment,
              hint: 'Respondendo...',
              compact: true,
            ),
          ),
      ],
    );
  }
}
