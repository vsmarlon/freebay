import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/social_post.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/comment_input.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/presentation/controllers/post_details_controller.dart';
import 'package:freebay/features/social/presentation/providers/post_details_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';
import 'package:freebay/features/social/presentation/providers/comment_likes_provider.dart';
import 'package:freebay/features/social/presentation/widgets/comment_item.dart';
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

    final activeController = isReply ? _replyController : _commentController;

    setState(() {
      if (isReply) {
        _isReplySending = true;
      } else {
        _isCommentSending = true;
      }
    });
    final controller = ref.read(postDetailsControllerProvider(widget.postId));
    final sent = await controller.sendComment(
      context,
      activeController,
      parentId: _replyToId,
    );

    if (sent && mounted) {
      setState(() => _replyToId = null);
      _replyController.clear();
    }
    if (mounted) {
      setState(() {
        if (isReply) {
          _isReplySending = false;
        } else {
          _isCommentSending = false;
        }
      });
    }
  }

  void _setReplyTo(CommentEntity comment) {
    setState(() => _replyToId = comment.id);
    // Seed only the reply controller, leaving the main input untouched.
    final username = comment.user?.displayName ?? 'usuário';
    _replyController.text = '@$username ';
    _replyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _replyController.text.length),
    );
    // Bring up keyboard focused on the reply field.
    Future.microtask(() => _replyFocusNode.requestFocus());
  }

  TreeNode<CommentEntity> _buildTree(List<CommentEntity> rootComments) {
    final root = TreeNode<CommentEntity>.root();
    for (final comment in rootComments) {
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
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: context.appBarColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PostDetailsState state) {
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
            Text(state.error!, style: TextStyle(color: context.textPrimary)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () =>
                  ref.read(postDetailsProvider(widget.postId).notifier).refresh(),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(gradient: AppColors.brutalistGradient),
                child: const Center(
                  child: Text(
                    'Tentar novamente',
                    style: TextStyle(
                        color: AppColors.onPrimary, fontWeight: FontWeight.w700),
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
    final isLiked = likesState.getLikedOverride(post.id) ?? post.isLiked;
    final likesCount = likesState.getCountOverride(post.id) ?? post.likesCount;

    final savesState = ref.watch(savesProvider);
    final isSaved = savesState.getSavedOverride(post.id) ?? post.isSaved;

    final repostsState = ref.watch(repostsProvider);
    final isReposted = repostsState.getRepostedOverride(post.id) ?? post.hasReposted;
    final sharesCount = repostsState.getCountOverride(post.id) ?? post.sharesCount;

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
              sharesCount: sharesCount,
              isLiked: isLiked,
              isSaved: isSaved,
              isReposted: isReposted,
              isVerified: post.user.isVerified,
              onUserTap: () => context.push('/user/${post.user.id}'),
              onLike: () async {
                final user =
                    ref.read(authControllerProvider).valueOrNull;
                if (user == null || user.isGuest) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, 'Faça login para curtir');
                  }
                  return false;
                }
                final success =
                    await ref.read(likesProvider.notifier).toggleLike(
                          post.id,
                          initialIsLiked: post.isLiked,
                          initialCount: post.likesCount,
                        );
                if (success) {
                  final newLikesState = ref.read(likesProvider);
                  ref.read(feedProvider.notifier).updatePostLike(
                        post.id,
                        newLikesState.getLikedOverride(post.id) ?? post.isLiked,
                        newLikesState.getCountOverride(post.id) ??
                            post.likesCount,
                      );
                  ref
                      .read(postDetailsProvider(widget.postId).notifier)
                      .refresh();
                }
                return success;
              },
              onSave: () async {
                final user = ref.read(authControllerProvider).valueOrNull;
                if (user == null || user.isGuest) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, 'Faça login para salvar');
                  }
                  return false;
                }
                return ref.read(savesProvider.notifier).toggleSave(
                      post.id,
                      initialIsSaved: post.isSaved,
                    );
              },
              onRepost: () async {
                final user = ref.read(authControllerProvider).valueOrNull;
                if (user == null || user.isGuest) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, 'Faça login para repostar');
                  }
                  return false;
                }
                final success = await ref.read(repostsProvider.notifier).toggleRepost(
                      post.id,
                      initialIsReposted: post.hasReposted,
                      initialCount: post.sharesCount,
                    );
                if (success) {
                  final newRepostsState = ref.read(repostsProvider);
                  ref.read(feedProvider.notifier).updateSharesCount(
                        post.id,
                        newRepostsState.getCountOverride(post.id) ?? post.sharesCount,
                      );
                  ref
                      .read(postDetailsProvider(widget.postId).notifier)
                      .refresh();
                }
                return success;
              },
              onComment: () => FocusScope.of(context).unfocus(),
              onShare: () async {
                final user = ref.read(authControllerProvider).valueOrNull;
                if (user == null || user.isGuest) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, 'Faça login para compartilhar');
                  }
                  return;
                }
                final result = await ref
                    .read(socialRepositoryProvider)
                    .sharePost(post.id, null);
                if (!context.mounted) return;
                result.fold(
                  (failure) => AppSnackbar.error(
                    context,
                    'Não foi possível compartilhar',
                  ),
                  (_) {
                    AppSnackbar.success(context, 'Compartilhado no seu perfil');
                    ref
                        .read(postDetailsProvider(widget.postId).notifier)
                        .refresh();
                  },
                );
              },
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Nenhum comentário ainda. Seja o primeiro!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecondary),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TreeView.simple<CommentEntity>(
                  tree: treeNode,
                  showRootNode: false,
                  expansionIndicatorBuilder: (context, node) =>
                      ChevronIndicator.rightDown(
                    tree: node,
                    color: context.textPrimary,
                    padding: const EdgeInsets.all(8),
                  ),
                  indentation:
                      const Indentation(style: IndentStyle.squareJoint),
                  builder: (context, node) {
                    final comment = node.data;
                    if (comment == null) return const SizedBox.shrink();
                    return _buildCommentNode(context, comment);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentNode(BuildContext context, CommentEntity comment) {
    final isReplying = _replyToId == comment.id;
    final commentLikesState = ref.watch(commentLikesProvider);
    final isCommentLiked = commentLikesState.getLikedOverride(comment.id) ?? comment.isLiked;
    final commentLikesCount = commentLikesState.getCountOverride(comment.id) ?? comment.likesCount;

    return Column(
      children: [
        CommentItem(
          comment: comment,
          isReplying: isReplying,
          isLiked: isCommentLiked,
          likesCount: commentLikesCount,
          onReply: () => _setReplyTo(comment),
          onLike: () async {
            final user = ref.read(authControllerProvider).valueOrNull;
            if (user == null || user.isGuest) {
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
              ? () => context.push('/user/${comment.user!.id}')
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
