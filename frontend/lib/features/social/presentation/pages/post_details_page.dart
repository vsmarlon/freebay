import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/social_post.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/comment_likes_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:go_router/go_router.dart';

class PostDetailsPage extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailsPage({super.key, required this.postId});

  @override
  ConsumerState<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends ConsumerState<PostDetailsPage> {
  final _commentController = TextEditingController();
  bool _isSending = false;
  String? _replyToId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final repository = ref.read(socialRepositoryProvider);
      final result = await repository.commentPost(
        widget.postId,
        content,
        parentId: _replyToId,
      );

      result.fold(
        (failure) {
          if (mounted) {
            AppSnackbar.error(context, failure.message);
          }
        },
        (_) {
          _commentController.clear();
          setState(() {
            _replyToId = null;
          });
          ref.read(postDetailsProvider(widget.postId).notifier).refresh();
          ref.invalidate(feedProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _setReplyTo(CommentEntity comment) {
    setState(() {
      _replyToId = comment.id;
    });
    final username = comment.user?.displayName ?? 'usuário';
    _commentController.text = '@$username ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    // Focus the text field
    FocusScope.of(context).requestFocus(FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  TreeNode<CommentEntity> _buildTree(List<CommentEntity> rootComments) {
    TreeNode<CommentEntity> rootNode = TreeNode.root();
    for (var comment in rootComments) {
      rootNode.add(_createNode(comment));
    }
    return rootNode;
  }

  TreeNode<CommentEntity> _createNode(CommentEntity comment) {
    var node = TreeNode<CommentEntity>(key: comment.id, data: comment);
    for (var reply in comment.replies) {
      node.add(_createNode(reply));
    }
    return node;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailsProvider(widget.postId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, state, isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PostDetailsState state, bool isDark) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => ref
                  .read(postDetailsProvider(widget.postId).notifier)
                  .refresh(),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: AppColors.brutalistGradient,
                ),
                child: const Center(
                  child: Text(
                    'Tentar novamente',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (state.post == null) {
      return const Center(child: Text('Post não encontrado'));
    }

    final post = state.post!;
    final treeNode = _buildTree(state.comments);

    final likesState = ref.watch(likesProvider);
    final isLiked = likesState.isLiked(post.id);
    final likesCount = likesState.getLikeCount(post.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(likesProvider.notifier).initializeSinglePost(
            post.id,
            post.isLiked,
            post.likesCount,
          );
      ref
          .read(commentLikesProvider.notifier)
          .initializeFromComments(state.comments);
    });

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(postDetailsProvider(widget.postId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SocialPost(
              userId: post.user.id,
              userName: post.user.displayName,
              userAvatarUrl: post.user.avatarUrl,
              content: post.content,
              imageUrl: post.imageUrl,
              likesCount: likesCount,
              commentsCount: post.commentsCount,
              sharesCount: post.sharesCount,
              isLiked: isLiked,
              onLike: () async {
                final authState = ref.read(authControllerProvider);
                final user = authState.valueOrNull;

                if (user == null || user.isGuest) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, 'Faça login para curtir');
                  }
                  return false;
                }

                final success =
                    await ref.read(likesProvider.notifier).toggleLike(post.id);
                if (success) {
                  ref
                      .read(postDetailsProvider(widget.postId).notifier)
                      .refresh();
                }
                return success;
              },
              onComment: () {
                // Focus the inline comment input
                FocusScope.of(context).unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).requestFocus(FocusNode());
                });
              },
              onShare: () {},
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
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildTopLevelCommentInput(isDark),
            ),
          ),
          if (state.comments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Nenhum comentário ainda. Seja o primeiro!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                // Use a finite height or shrink wrap tree view. If there are many nodes, treeview requires bounded height.
                // We'll wrap TreeView in a fixed height or handle its expandability.
                // TreeView implements scrollable natively, so we might need constraints
                height: MediaQuery.of(context).size.height * 0.6,
                child: TreeView.simple<CommentEntity>(
                  tree: treeNode,
                  showRootNode: false,
                  expansionIndicatorBuilder: (context, node) =>
                      ChevronIndicator.rightDown(
                    tree: node,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                    padding: const EdgeInsets.all(8),
                  ),
                  indentation:
                      const Indentation(style: IndentStyle.squareJoint),
                  builder: (context, node) {
                    final comment = node.data;
                    if (comment == null) return const SizedBox.shrink();
                    return _buildCommentItem(comment, isDark);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentEntity comment, bool isDark) {
    final isReplying = _replyToId == comment.id;
    final commentLikesState = ref.watch(commentLikesProvider);
    final isCommentLiked = commentLikesState.isLiked(comment.id);
    final commentLikesCount = commentLikesState.getLikeCount(comment.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (comment.user != null) {
                    context.push('/user/${comment.user!.id}');
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
                    image: comment.user?.avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(comment.user!.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: comment.user?.avatarUrl == null
                      ? Icon(Icons.person,
                          size: 16,
                          color:
                              isDark ? AppColors.white : AppColors.mediumGray)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (comment.user != null) {
                          context.push('/user/${comment.user!.id}');
                        }
                      },
                      child: Text(
                        comment.user?.displayName ?? 'Usuário',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white : AppColors.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.mediumGray
                                : AppColors.mediumGray,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _setReplyTo(comment),
                          child: Text(
                            'Responder',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primaryPurpleLight
                                  : AppColors.primaryPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () async {
                            final authState = ref.read(authControllerProvider);
                            final user = authState.valueOrNull;

                            if (user == null || user.isGuest) {
                              if (context.mounted) {
                                AppSnackbar.warning(
                                    context, 'Faça login para curtir');
                              }
                              return;
                            }

                            await ref
                                .read(commentLikesProvider.notifier)
                                .toggleLike(comment.id);
                          },
                          child: Row(
                            children: [
                              Icon(
                                isCommentLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 14,
                                color: isCommentLiked
                                    ? Colors.red
                                    : (isDark
                                        ? AppColors.mediumGray
                                        : AppColors.mediumGray),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                commentLikesCount > 0
                                    ? commentLikesCount.toString()
                                    : '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCommentLiked
                                      ? Colors.red
                                      : (isDark
                                          ? AppColors.mediumGray
                                          : AppColors.mediumGray),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isReplying) ...[
            const SizedBox(height: 8),
            _buildInlineReplyInput(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineReplyInput(bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: TextField(
            controller: _commentController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escreva sua resposta...',
              hintStyle: TextStyle(color: AppColors.mediumGray),
               border: const OutlineInputBorder(
                 borderRadius: BorderRadius.zero,
                 borderSide: BorderSide.none,
               ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.lightGray,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              isDense: true,
            ),
            style:
                TextStyle(color: isDark ? AppColors.white : AppColors.darkGray),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendComment(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isSending ? null : _sendComment,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: AppColors.brutalistGradient,
            ),
            child: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTopLevelCommentInput(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Adicionar comentário...',
              hintStyle: TextStyle(color: AppColors.mediumGray),
               border: const OutlineInputBorder(
                 borderRadius: BorderRadius.zero,
                 borderSide: BorderSide.none,
               ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.lightGray,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            style:
                TextStyle(color: isDark ? AppColors.white : AppColors.darkGray),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendComment(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isSending ? null : _sendComment,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: AppColors.brutalistGradient,
            ),
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} d';
    if (diff.inHours > 0) return '${diff.inHours} h';
    if (diff.inMinutes > 0) return '${diff.inMinutes} m';
    return 'agora';
  }
}
