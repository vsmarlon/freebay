import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';
import 'package:freebay/features/social/presentation/providers/comment_context_provider.dart';
import 'package:freebay/features/social/presentation/providers/comment_likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/widgets/comment_item.dart';
import 'package:freebay/features/social/presentation/widgets/mention_suggestions.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/storage_service.dart';

/// A reply is a full-width focus, never a progressively indented tree.
class CommentContextPage extends ConsumerStatefulWidget {
  final String postId;
  final String commentId;

  const CommentContextPage({
    super.key,
    required this.postId,
    required this.commentId,
  });

  @override
  ConsumerState<CommentContextPage> createState() => _CommentContextPageState();
}

class _CommentContextPageState extends ConsumerState<CommentContextPage> {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  final _scrollController = ScrollController();
  bool _sending = false;
  String _replySort = 'recent';
  String? _draftOwner;
  String? _draftKey;
  bool _draftLoaded = false;
  int _draftGeneration = 0;
  String? _pendingClientRequestId;
  String? _pendingContent;

  @override
  void dispose() {
    _composer.dispose();
    _composerFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(CommentEntity target) async {
    final rawContent = _composer.text;
    final content = rawContent.trim();
    if (content.isEmpty || content.characters.length > 280 || _sending) return;
    if (_pendingContent != null && _pendingContent != content) return;
    final requestId = _pendingClientRequestId ??= const Uuid().v4();
    _pendingContent = content;
    final accountId = _draftOwner;
    final draftKey = _draftKey;
    final draftGeneration = _draftGeneration;
    final postId = widget.postId;
    final commentId = widget.commentId;
    _persistDraft(rawContent);
    setState(() => _sending = true);
    final result = await ref
        .read(socialRepositoryProvider)
        .createComment(
          widget.postId,
          content,
          parentId: target.id,
          clientRequestId: requestId,
        );
    if (!mounted ||
        draftGeneration != _draftGeneration ||
        draftKey != _draftKey ||
        accountId != _draftOwner ||
        postId != widget.postId ||
        commentId != widget.commentId ||
        accountId != ref.read(authControllerProvider).value?.id) {
      return;
    }
    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      if (_composer.text == rawContent &&
          _pendingClientRequestId == requestId &&
          _pendingContent == content) {
        _composer.clear();
        _pendingClientRequestId = null;
        _pendingContent = null;
        _persistDraft('');
      } else if (_pendingClientRequestId == requestId &&
          _pendingContent == content) {
        _pendingClientRequestId = null;
        _pendingContent = null;
      }
      ref
          .read(
            commentContextControllerProvider(
              commentId,
              replySort: _replySort,
            ).notifier,
          )
          .refresh();
    });
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = ref.watch(authControllerProvider).value?.id;
    _restoreDraft(ownerId);
    final provider = commentContextControllerProvider(
      widget.commentId,
      replySort: _replySort,
    );
    final state = ref.watch(provider);
    final contextValue = state.asData?.value.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(text: l10n(context).feedComments),
            Expanded(
              child: state.when(
                loading: () => const Center(child: ShimmerBlock(height: 84)),
                error: (error, _) => EmptyState.error(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(provider),
                ),
                data: (thread) {
                  final current = thread.value;
                  if (current.focus.postId != widget.postId) {
                    return Center(child: Text(l10n(context).feedPostNotFound));
                  }
                  final entries = [
                    ...current.ancestors,
                    current.focus,
                    ...current.replies,
                  ];
                  final focusIndex = current.ancestors.length;
                  final hasAncestorControl =
                      current.nextAncestorCursor != null ||
                      thread.ancestorError != null;
                  final hasReplyControl =
                      current.nextReplyCursor != null ||
                      thread.replyError != null;
                  final commentStart = hasAncestorControl ? 2 : 1;
                  final replyControlIndex = commentStart + entries.length;
                  final rowKeys = <Key>[
                    const ValueKey('conversation-header'),
                    if (hasAncestorControl) const ValueKey('load-ancestors'),
                    ...entries.map(
                      (comment) => ValueKey('comment:${comment.id}'),
                    ),
                    if (hasReplyControl) const ValueKey('load-replies'),
                    const ValueKey('conversation-bottom'),
                  ];
                  final rowIndexes = {
                    for (var i = 0; i < rowKeys.length; i++) rowKeys[i]: i,
                  };
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.read(provider.notifier).refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: rowKeys.length,
                      findChildIndexCallback: (key) => rowIndexes[key],
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                            ),
                            child: Row(
                              children: [
                                DropdownButton<String>(
                                  value: _replySort,
                                  onChanged: (sort) {
                                    if (sort == null || sort == _replySort) {
                                      return;
                                    }
                                    setState(() => _replySort = sort);
                                  },
                                  items: [
                                    DropdownMenuItem(
                                      value: 'recent',
                                      child: Text(
                                        l10n(context).socialCommentsRecent,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'likes',
                                      child: Text(
                                        l10n(context).socialCommentsPopular,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        if (hasReplyControl && index == replyControlIndex) {
                          return _pageControl(
                            error: thread.replyError,
                            isLoading: thread.loadingReplies,
                            onPressed: () =>
                                ref.read(provider.notifier).loadReplies(),
                          );
                        }
                        if (hasAncestorControl && index == 1) {
                          return _pageControl(
                            error: thread.ancestorError,
                            isLoading: thread.loadingAncestors,
                            onPressed: () =>
                                ref.read(provider.notifier).loadAncestors(),
                          );
                        }
                        if (index == rowKeys.length - 1) {
                          return const SizedBox(height: 8);
                        }
                        final entryIndex = index - commentStart;
                        if (entryIndex < 0 || entryIndex >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final isFocus = entryIndex == focusIndex;
                        final sourceComment = entries[entryIndex];
                        final comment = isFocus
                            ? sourceComment.copyWith(replies: current.replies)
                            : sourceComment;
                        return ColoredBox(
                          key: rowKeys[index],
                          color: isFocus
                              ? context.surfaceHighColor
                              : context.bgColor,
                          child: CommentItem(
                            comment: comment,
                            isReplying: false,
                            isLiked:
                                ref
                                    .watch(commentLikesProvider)
                                    .getLikedOverride(comment.id) ??
                                comment.isLiked,
                            likesCount:
                                ref
                                    .watch(commentLikesProvider)
                                    .getCountOverride(comment.id) ??
                                comment.likesCount,
                            onReply: () => context.push(
                              AppRoutes.commentPath(widget.postId, comment.id),
                            ),
                            onLike: () => ref
                                .read(commentLikesProvider.notifier)
                                .toggleLike(
                                  comment.id,
                                  initialIsLiked: comment.isLiked,
                                  initialCount: comment.likesCount,
                                ),
                            onUserTap: comment.user == null
                                ? null
                                : () => context.push(
                                    AppRoutes.userPath(comment.user!.id),
                                  ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: contextValue == null
                    ? const SizedBox.shrink()
                    : CommentInput(
                        controller: _composer,
                        focusNode: _composerFocus,
                        isSending: _sending,
                        hint: l10n(context).feedReplyingHint,
                        onSend: () => _send(contextValue.focus),
                        onChanged: _onDraftChanged,
                        suggestions: MentionSuggestions(
                          controller: _composer,
                          focusNode: _composerFocus,
                        ),
                        onDiscard: () {
                          _composer.clear();
                          _pendingClientRequestId = null;
                          _pendingContent = null;
                          _persistDraft('');
                          FocusScope.of(context).unfocus();
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageControl({
    required String? error,
    required bool isLoading,
    required VoidCallback onPressed,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
    child: Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text(error, style: TextStyle(color: context.textSecondary)),
          ),
        AppButton(
          label: isLoading
              ? l10n(context).commonLoading
              : error == null
              ? l10n(context).socialCommentsLoadMore
              : l10n(context).commonRetry,
          variant: AppButtonVariant.ghost,
          onPressed: isLoading ? null : onPressed,
        ),
      ],
    ),
  );

  void _restoreDraft(String? ownerId) {
    final key = ownerId == null
        ? null
        : 'social.comment.${widget.postId}.${widget.commentId}';
    if (ownerId == _draftOwner && key == _draftKey) return;
    _draftOwner = ownerId;
    _draftKey = key;
    _draftLoaded = false;
    _sending = false;
    _pendingClientRequestId = null;
    _pendingContent = null;
    final generation = ++_draftGeneration;
    _composer.clear();
    if (ownerId == null || key == null) {
      _draftLoaded = true;
      return;
    }
    StorageService.readCachedJson(userId: ownerId, key: key).then((draft) {
      if (!mounted || generation != _draftGeneration || _draftKey != key) {
        return;
      }
      final content = draft?['content'];
      final requestId = draft?['clientRequestId'];
      if (content is String && _composer.text.isEmpty) {
        _composer.value = TextEditingValue(
          text: content,
          selection: TextSelection.collapsed(offset: content.length),
        );
        if (requestId is String) {
          _pendingClientRequestId = requestId;
          _pendingContent = content.trim();
        }
      }
      _draftLoaded = true;
    });
  }

  void _persistDraft(String content) {
    final ownerId = _draftOwner;
    final key = _draftKey;
    if (!_draftLoaded || ownerId == null || key == null) return;
    StorageService.writeCachedJson(
      userId: ownerId,
      key: key,
      json: {
        'content': content,
        if (_pendingClientRequestId != null)
          'clientRequestId': _pendingClientRequestId,
      },
    );
  }

  void _onDraftChanged(String content) {
    if (_pendingContent != null && _pendingContent != content.trim()) {
      _pendingClientRequestId = null;
      _pendingContent = null;
    }
    _persistDraft(content);
  }
}
