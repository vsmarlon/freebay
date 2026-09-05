import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';

class CommentsPage extends ConsumerStatefulWidget {
  final String postId;

  const CommentsPage({super.key, required this.postId});

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  final _newCommentController = TextEditingController();
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();

  List<CommentEntity> _comments = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String? _activeReplyId;
  int _treeVersion = 0;
  TreeNode<CommentEntity> _rootNode = TreeNode.root();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _syncTree({bool bumpVersion = true}) {
    final root = TreeNode<CommentEntity>.root();
    for (final comment in _comments) {
      final node = TreeNode<CommentEntity>(key: comment.id, data: comment);
      _addReplies(node, comment.replies, 2);
      root.add(node);
    }
    _rootNode = root;
    if (bumpVersion) _treeVersion++;
  }

  void _addReplies(
    TreeNode<CommentEntity> parent,
    List<CommentEntity> replies,
    int depth,
  ) {
    for (final reply in replies) {
      final node = TreeNode<CommentEntity>(key: reply.id, data: reply);
      parent.add(node);
      if (reply.replies.isNotEmpty) {
        _addReplies(depth >= 4 ? parent : node, reply.replies, depth + 1);
      }
    }
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(socialRepositoryProvider);
    final result = await repo.getComments(widget.postId);

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (comments) => setState(() {
        _comments = refresh ? comments : [..._comments, ...comments];
        _isLoading = false;
        _syncTree();
      }),
    );
  }

  Future<void> _refreshAfterSend() async {
    final repo = ref.read(socialRepositoryProvider);
    final result = await repo.getComments(widget.postId);
    result.fold((_) {}, (comments) {
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _syncTree(bumpVersion: false);
      });
    });
  }

  void _activateReply(String nodeKey, {String? displayName}) {
    _replyController.clear();
    setState(() => _activeReplyId = nodeKey);
    if (displayName != null) {
      _replyController.text = '@$displayName ';
      _replyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _replyController.text.length),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _replyFocusNode.requestFocus();
    });
  }

  void _cancelReply() {
    _replyController.clear();
    _replyFocusNode.unfocus();
    setState(() => _activeReplyId = null);
  }

  Future<void> _sendComment(String content, {String? parentId}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    setState(() => _isSending = true);
    final repo = ref.read(socialRepositoryProvider);
    final result = await repo.commentPost(
      widget.postId,
      trimmed,
      parentId: parentId,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        if (parentId != null) {
          _cancelReply();
        } else {
          _newCommentController.clear();
        }
        ref
            .read(feedProvider.notifier)
            .updatePostCommentCount(widget.postId, 1);
        _refreshAfterSend();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'COMENTÁRIOS',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          _buildInputBar(),
          Expanded(child: _buildTreeBody(context)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.surfaceMidColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newCommentController,
              decoration: InputDecoration(
                hintText: 'Adicionar comentário...',
                hintStyle: TextStyle(
                  color: context.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: context.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: TextStyle(color: context.textPrimary, fontSize: 14),
              onSubmitted: (t) => _sendComment(t),
            ),
          ),
          Spacing.hSm,
          BrutalistIconButton(
            icon: Icons.send,
            onTap: () => _sendComment(_newCommentController.text),
            iconColor: AppColors.onPrimary,
            backgroundColor: AppColors.primaryContainer,
            isLoading: _isSending,
          ),
        ],
      ),
    );
  }

  Widget _buildTreeBody(BuildContext context) {
    if (_isLoading && _comments.isEmpty) {
      return const SkeletonPage(
        child: Column(
          children: [
            SizedBox(height: 16),
            ShimmerBlock(height: 60),
            SizedBox(height: 12),
            ShimmerBlock(height: 60),
            SizedBox(height: 12),
            ShimmerBlock(height: 60),
          ],
        ),
      );
    }
    if (_error != null && _comments.isEmpty) {
      return Center(
        child: Text(_error!, style: TextStyle(color: context.textPrimary)),
      );
    }
    if (_comments.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'NENHUM COMENTÁRIO',
        subtitle: 'Seja o primeiro a comentar.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadComments(refresh: true),
      child: TreeView.simple<CommentEntity>(
        key: ValueKey(_treeVersion),
        tree: _rootNode,
        showRootNode: false,
        builder: (context, node) => node.data == null
            ? const SizedBox.shrink()
            : _buildCommentNode(node),
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        indentation: const Indentation(
          width: 24,
          style: IndentStyle.squareJoint,
        ),
      ),
    );
  }

  Widget _buildCommentNode(ITreeNode<CommentEntity> node) {
    final comment = node.data!;
    final isReplying = _activeReplyId == node.key;

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                color: context.surfaceColor,
                child: const Icon(
                  Icons.person,
                  size: 14,
                  color: AppColors.mediumGray,
                ),
              ),
              Spacing.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user?.displayName ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                    ),
                    if (comment.replies.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${comment.replies.length} ${comment.replies.length == 1 ? "resposta" : "respostas"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => isReplying
                          ? _cancelReply()
                          : _activateReply(
                              node.key,
                              displayName: comment.user?.displayName,
                            ),
                      child: Text(
                        isReplying ? 'Cancelar' : 'Responder',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isReplying
                              ? AppColors.error
                              : AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isReplying) ...[
            Spacing.vSm,
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      focusNode: _replyFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            'Responder a ${comment.user?.displayName ?? 'usuário'}...',
                        hintStyle: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: context.surfaceColor,
                        isDense: true,
                      ),
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 12,
                      ),
                      onSubmitted: (t) => _sendComment(t, parentId: comment.id),
                    ),
                  ),
                  Spacing.hXs,
                  IconButton(
                    icon: const Icon(Icons.send, size: 16),
                    onPressed: () => _sendComment(
                      _replyController.text,
                      parentId: comment.id,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
