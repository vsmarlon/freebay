import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

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

  void _syncTree() {
    final root = TreeNode<CommentEntity>.root();
    for (final comment in _comments) {
      final node = TreeNode<CommentEntity>(key: comment.id, data: comment);
      for (final reply in comment.replies) {
        node.add(TreeNode<CommentEntity>(key: reply.id, data: reply));
      }
      root.add(node);
    }
    _rootNode = root;
    _treeVersion++;
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) _comments = [];
    });

    try {
      final repo = ref.read(socialRepositoryProvider);
      final result = await repo.getComments(widget.postId);

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
    } catch (_) {
      setState(() {
        _error = 'Erro ao carregar comentários';
        _isLoading = false;
      });
    }
  }

  void _activateReply(String nodeKey) {
    _replyController.clear();
    setState(() => _activeReplyId = nodeKey);
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

    try {
      final repo = ref.read(socialRepositoryProvider);
      final result = await repo.commentPost(
        widget.postId,
        trimmed,
        parentId: parentId,
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (_) {
          if (parentId != null) {
            _cancelReply();
          } else {
            _newCommentController.clear();
          }
          _loadComments(refresh: true);
        },
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Comentários',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildNewCommentInput(isDark),
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
          ),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildNewCommentInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.lightGray,
            child:
                const Icon(Icons.person, size: 16, color: AppColors.mediumGray),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _newCommentController,
              decoration: InputDecoration(
                hintText: 'Adicionar comentário...',
                hintStyle: const TextStyle(
                  color: AppColors.mediumGray,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.backgroundDark : AppColors.lightGray,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.darkGray,
                fontSize: 14,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendComment,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending
                ? null
                : () => _sendComment(_newCommentController.text),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
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
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading && _comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }
    if (_error != null && _comments.isEmpty) return _buildError(isDark);
    if (_comments.isEmpty) return _buildEmpty(isDark);

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: () => _loadComments(refresh: true),
      child: TreeView.simple<CommentEntity>(
        key: ValueKey(_treeVersion),
        tree: _rootNode,
        showRootNode: false,
        builder: (context, node) {
          if (node.data == null) return const SizedBox.shrink();
          return _buildNode(isDark, node);
        },
        padding: const EdgeInsets.symmetric(vertical: 8),
        expansionBehavior: ExpansionBehavior.snapToTop,
        indentation: const Indentation(
          width: 28,
          style: IndentStyle.squareJoint,
        ),
      ),
    );
  }

  Widget _buildNode(bool isDark, ITreeNode<CommentEntity> node) {
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
              CircleAvatar(
                radius: 15,
                backgroundColor:
                    isDark ? AppColors.surfaceDark : AppColors.lightGray,
                child: const Icon(
                  Icons.person,
                  size: 15,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.user?.displayName ?? 'Usuário',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color:
                                isDark ? AppColors.white : AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.white : AppColors.darkGray,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => isReplying
                          ? _cancelReply()
                          : _activateReply(node.key),
                      child: Text(
                        isReplying ? 'Cancelar' : 'Responder',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isReplying
                              ? AppColors.error
                              : AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isReplying) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      focusNode: _replyFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            'Responder a ${comment.user?.displayName ?? 'usuário'}...',
                        hintStyle: const TextStyle(
                          color: AppColors.mediumGray,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.lightGray,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.darkGray,
                        fontSize: 13,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) => _sendComment(v, parentId: comment.id),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _isSending
                        ? null
                        : () => _sendComment(
                              _replyController.text,
                              parentId: comment.id,
                            ),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 14,
                            ),
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

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Erro ao carregar comentários',
            style: TextStyle(
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadComments(refresh: true),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum comentário ainda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seja o primeiro a comentar!',
            style: TextStyle(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'agora';
  }
}
