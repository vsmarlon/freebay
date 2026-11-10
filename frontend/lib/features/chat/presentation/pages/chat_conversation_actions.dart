part of 'chat_conversation_page.dart';

mixin _ChatConversationActions on ConsumerState<ChatConversationPage> {
  TextEditingController get _messageController;
  ScrollController get _scrollController;
  int get _conversationGeneration;
  bool get _scrollPostFrameQueued;
  set _scrollPostFrameQueued(bool value);
  bool get _scrollAnimating;
  set _scrollAnimating(bool value);
  bool get _isQuoteNavigationActive;
  void _scrollToBottom([int? generation]) {
    final expectedGeneration = generation ?? _conversationGeneration;
    if (!mounted ||
        _isQuoteNavigationActive ||
        _scrollPostFrameQueued ||
        _scrollAnimating) {
      return;
    }
    _scrollPostFrameQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollPostFrameQueued = false;
      if (!mounted ||
          expectedGeneration != _conversationGeneration ||
          _isQuoteNavigationActive ||
          !_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        return;
      }
      _scrollAnimating = true;
      _scrollController
          .animateTo(
            _scrollController.position.maxScrollExtent,
            duration: AppMotion.enter,
            curve: AppMotion.enterCurve,
          )
          .whenComplete(() => _scrollAnimating = false);
    });
  }

  bool get _isSending;
  set _isSending(bool value);
  String? get _pendingOptimisticMessageId;
  set _pendingOptimisticMessageId(String? value);
  ConversationMessagesNotifier? get _pendingOptimisticNotifier;
  set _pendingOptimisticNotifier(ConversationMessagesNotifier? value);
  String? get _pendingDraftText;
  set _pendingDraftText(String? value);
  CancelToken? get _sendCancelToken;
  set _sendCancelToken(CancelToken? value);
  Timer? get _sendSlowTimer;
  set _sendSlowTimer(Timer? value);
  MessageEntity? get _replyTarget;
  set _replyTarget(MessageEntity? value);
  String? _takeReplyTarget() {
    final replyId = _replyTarget?.id;
    if (replyId != null && mounted) setState(() => _replyTarget = null);
    return replyId;
  }

  bool get _viewOnceEnabled;
  set _viewOnceEnabled(bool value);
  set _isRecording(bool value);
  ConversationMessagesNotifier get _notifier;
  Set<String> get _selectedMessageIds;
  set _isSelecting(bool value);
  ChatThreadType get _threadType;

  CancelToken _beginSend([CancelToken? requestToken]) {
    final token = requestToken ?? CancelToken();
    _sendCancelToken = token;
    _sendSlowTimer?.cancel();
    unawaited(token.whenCancel.then((_) => _releaseCancelledSend(token)));
    _sendSlowTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted ||
          token.isCancelled ||
          !identical(_sendCancelToken, token)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n(context).chatSendingSlow),
          action: SnackBarAction(
            label: l10n(context).commonCancel,
            onPressed: () => _cancelSend(token),
          ),
        ),
      );
    });
    return token;
  }

  void _cancelSend(CancelToken token) {
    if (!mounted || !identical(_sendCancelToken, token)) return;
    if (!token.isCancelled) token.cancel('Cancelled by user');
    _releaseCancelledSend(token, showFeedback: true);
  }

  void _releaseCancelledSend(CancelToken token, {bool showFeedback = false}) {
    if (!mounted || !identical(_sendCancelToken, token)) return;
    _sendSlowTimer?.cancel();
    _sendSlowTimer = null;
    _sendCancelToken = null;
    setState(() => _isSending = false);
    final pendingId = _pendingOptimisticMessageId;
    if (pendingId != null) {
      final notifier = _pendingOptimisticNotifier;
      notifier?.markDeliveryUncertain(pendingId);
      _pendingOptimisticMessageId = null;
      _pendingOptimisticNotifier = null;
      final draft = _pendingDraftText;
      if (draft != null && _messageController.text.isEmpty) {
        _messageController.text = draft;
      }
      _pendingDraftText = null;
      if (notifier != null) unawaited(notifier.refresh());
      if (showFeedback) {
        AppSnackbar.show(
          context,
          message: l10n(context).chatSendDeliveryUncertain,
          action: SnackBarAction(
            label: l10n(context).commonRetry.toUpperCase(),
            onPressed: () {
              if (_messageController.text.trim() == draft && draft != null) {
                unawaited(_sendMessage(clientMessageId: pendingId));
              }
            },
          ),
        );
        return;
      }
    }
  }

  bool _ownsSend(CancelToken token, int generation) =>
      mounted &&
      generation == _conversationGeneration &&
      identical(_sendCancelToken, token) &&
      !token.isCancelled;

  void _finishSend(CancelToken token, int generation) {
    if (!mounted ||
        generation != _conversationGeneration ||
        !identical(_sendCancelToken, token)) {
      return;
    }
    _sendSlowTimer?.cancel();
    _sendSlowTimer = null;
    _sendCancelToken = null;
    if (_isSending) setState(() => _isSending = false);
  }

  Future<void> _sendMessage({String? clientMessageId}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    final generation = _conversationGeneration;
    final currentUserId = ref.read(authControllerProvider).value?.id;
    final replyId = _replyTarget?.id;
    final viewOnce = _viewOnceEnabled;
    final cancelToken = _beginSend();
    _messageController.clear();
    final uncertain = ref
        .read(conversationMessagesProvider(widget.chatId))
        .messages
        .where(
          (message) =>
              message.metadata?['_deliveryUncertain'] == true &&
              message.content == text,
        );
    final tempId =
        clientMessageId ??
        (uncertain.isEmpty ? null : uncertain.first.clientMessageId) ??
        'temp-${DateTime.now().millisecondsSinceEpoch}';
    _pendingOptimisticMessageId = tempId;
    final notifier = _notifier;
    _pendingOptimisticNotifier = notifier;
    _pendingDraftText = text;
    final optimisticMessage = MessageEntity(
      id: tempId,
      conversationId: widget.chatId,
      senderId: currentUserId ?? '',
      clientMessageId: tempId,
      content: text,
      replyToId: replyId,
      createdAt: DateTime.now(),
      viewOnce: viewOnce,
    );
    setState(() {
      _replyTarget = null;
      _viewOnceEnabled = false;
      _isSending = true;
    });
    notifier.addOptimistic(optimisticMessage);
    _scrollToBottom();
    try {
      final result = await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            widget.chatId,
            text,
            replyToId: replyId,
            viewOnce: viewOnce,
            clientMessageId: tempId,
            cancelToken: cancelToken,
          );
      if (!_ownsSend(cancelToken, generation)) {
        result.fold((_) {}, (sent) => notifier.confirmSent(tempId, sent));
        return;
      }
      result.fold(
        (failure) {
          notifier.removeByIds({tempId});
          if (_messageController.text.isEmpty) _messageController.text = text;
          _pendingOptimisticMessageId = null;
          _pendingOptimisticNotifier = null;
          _pendingDraftText = null;
          AppSnackbar.handleFailure(context, failure);
        },
        (sent) {
          notifier.confirmSent(tempId, sent);
          _pendingOptimisticMessageId = null;
          _pendingOptimisticNotifier = null;
          _pendingDraftText = null;
          _scrollToBottom();
          ref.read(liveChatListProvider.notifier).refreshRecent();
        },
      );
    } finally {
      if (_pendingOptimisticMessageId == tempId &&
          identical(_sendCancelToken, cancelToken)) {
        _pendingOptimisticMessageId = null;
        _pendingOptimisticNotifier = null;
        _pendingDraftText = null;
      }
      _finishSend(cancelToken, generation);
    }
  }

  Future<void> _sendAudio(AudioRecording recording) async {
    final generation = _conversationGeneration;
    final chatId = widget.chatId;
    final replyId = _takeReplyTarget();
    final viewOnce = _viewOnceEnabled;
    final cancelToken = _beginSend();
    setState(() {
      _isRecording = false;
      _isSending = true;
    });
    try {
      final upload = await UploadService.uploadFile(
        recording.file,
        'chat',
        cancelToken: cancelToken,
      );
      if (!_ownsSend(cancelToken, generation)) return;
      final url = upload.rightOrNull;
      if (url == null) {
        if (mounted) {
          AppSnackbar.error(context, l10n(context).chatSendFailed);
        }
        return;
      }
      if (!_ownsSend(cancelToken, generation)) return;
      final result = await ref
          .read(chatRepositoryProvider)
          .sendRichMessage(
            conversationId: chatId,
            type: MessageType.audio,
            attachmentUrl: url,
            replyToId: replyId,
            durationMs: recording.duration.inMilliseconds,
            viewOnce: viewOnce,
            cancelToken: cancelToken,
          );
      if (!_ownsSend(cancelToken, generation)) return;
      result.fold((f) => AppSnackbar.error(context, f.message), (sent) {
        if (viewOnce) setState(() => _viewOnceEnabled = false);
        _notifier.confirmSent(sent.id, sent);
        _scrollToBottom();
        ref.read(liveChatListProvider.notifier).refreshRecent();
      });
    } finally {
      try {
        await recording.file.delete();
      } catch (_) {}
      _finishSend(cancelToken, generation);
    }
  }

  Future<void> _sendLocation({
    required Map<String, dynamic> metadata,
    required String? replyToId,
    required String clientMessageId,
  }) async {
    if (_isSending) return;
    final generation = _conversationGeneration;
    final cancelToken = _beginSend();
    setState(() => _isSending = true);
    try {
      final result = await _notifier.sendLocation(
        metadata: metadata,
        replyToId: replyToId,
        clientMessageId: clientMessageId,
        cancelToken: cancelToken,
      );
      if (!_ownsSend(cancelToken, generation)) return;
      result.fold(
        (failure) => AppSnackbar.error(
          context,
          localizedFailureMessage(context, failure),
          action: SnackBarAction(
            label: l10n(context).commonRetry.toUpperCase(),
            onPressed: () => _sendLocation(
              metadata: metadata,
              replyToId: replyToId,
              clientMessageId: clientMessageId,
            ),
          ),
        ),
        (_) {
          _scrollToBottom();
          ref.read(liveChatListProvider.notifier).refreshRecent();
        },
      );
    } finally {
      _finishSend(cancelToken, generation);
    }
  }

  Future<bool> _sendRich({
    required MessageType type,
    String? content,
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce = false,
    CancelToken? cancelToken,
  }) async {
    if (!mounted || _isSending) return false;
    final generation = _conversationGeneration;
    final requestToken = _beginSend(cancelToken);
    setState(() => _isSending = true);
    try {
      final result = await ref
          .read(chatRepositoryProvider)
          .sendRichMessage(
            conversationId: widget.chatId,
            content: content,
            type: type,
            attachmentUrl: attachmentUrl,
            replyToId: replyToId,
            metadata: metadata,
            viewOnce: viewOnce,
            cancelToken: requestToken,
          );
      if (!_ownsSend(requestToken, generation)) {
        return false;
      }
      return result.fold(
        (failure) {
          AppSnackbar.handleFailure(context, failure);
          return false;
        },
        (sent) {
          _notifier.confirmSent(sent.id, sent);
          if (viewOnce && mounted) {
            setState(() => _viewOnceEnabled = false);
          }
          _scrollToBottom();
          ref.read(liveChatListProvider.notifier).refreshRecent();
          return true;
        },
      );
    } finally {
      _finishSend(requestToken, generation);
    }
  }

  void _deleteSelectedMessages() {
    final chatId = widget.chatId;
    final repository = ref.read(chatRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final ids = Set<String>.from(_selectedMessageIds);
    final messages = ref
        .read(conversationMessagesProvider(widget.chatId))
        .messages;
    final removed = messages.where((m) => ids.contains(m.id)).toList();
    final indexes = <String, int>{};
    for (var i = 0; i < messages.length; i++) {
      if (ids.contains(messages[i].id)) {
        indexes[messages[i].id] = i;
      }
    }
    _notifier.removeByIds(ids);
    setState(() {
      _selectedMessageIds.clear();
      _isSelecting = false;
    });
    AppSnackbar.undoable(
      context,
      message: l10n(context).chatDeletedMessages(ids.length),
      onUndo: () {
        if (!mounted || widget.chatId != chatId) return;
        final current = ref.read(conversationMessagesProvider(chatId)).messages;
        for (final m in removed) {
          _notifier.insertMessage(indexes[m.id] ?? current.length, m);
        }
      },
      onCommit: () async {
        var failed = false;
        for (final id in ids) {
          final result = await repository.deleteMessage(chatId, id);
          if (result.isLeft) failed = true;
        }
        if (failed) {
          if (mounted && widget.chatId == chatId) await _notifier.refresh();
          if (messenger.mounted) {
            AppSnackbar.errorOnMessenger(
              messenger,
              l10n(messenger.context).chatDeleteSomeFailed,
            );
          }
        }
      },
    );
  }

  void _showMenu() {
    final preference = ref
        .read(conversationMessagesProvider(widget.chatId))
        .preference;
    showConversationMenu(
      context: context,
      isArchived: preference?.isArchived == true,
      isMuted: preference?.muted == true,
      onCustomize: _showCustomizeSheet,
      onMute: _toggleMute,
      onArchive: () async {
        final isArchived = preference?.isArchived ?? false;
        final result = await ref
            .read(chatRepositoryProvider)
            .archiveChat(widget.chatId, _threadType, !isArchived);
        if (!mounted) return;
        result.fold((failure) => AppSnackbar.handleFailure(context, failure), (
          _,
        ) {
          final current = ref
              .read(conversationMessagesProvider(widget.chatId))
              .preference;
          if (current != null) {
            _notifier.setPreference(current.copyWith(isArchived: !isArchived));
          }
          ref.invalidate(chatsProvider);
          ref.invalidate(liveChatListProvider);
          ref.invalidate(archivedChatListProvider);
          context.pop();
        });
      },
      onDelete: _confirmDeleteConversation,
    );
  }

  Future<void> _toggleMute() async {
    final conversation = ref.read(conversationMessagesProvider(widget.chatId));
    if (conversation.threadType == null) return;
    final muted = !(conversation.preference?.muted ?? false);
    final result = await ref
        .read(chatRepositoryProvider)
        .setMuted(widget.chatId, _threadType, muted);
    if (!mounted) return;
    result.fold((failure) => AppSnackbar.handleFailure(context, failure), (
      preference,
    ) {
      _notifier.setPreference(preference);
      ref.invalidate(chatsProvider);
      ref.invalidate(liveChatListProvider);
      ref.invalidate(archivedChatListProvider);
      AppSnackbar.info(
        context,
        preference.muted
            ? l10n(context).chatNotificationsMuted
            : l10n(context).chatNotificationsEnabled,
      );
    });
  }

  void _confirmDeleteConversation() {
    showBrutalistSheet(
      context: context,
      title: l10n(context).chatDeleteTitle,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n(ctx).chatDeleteAllMessagesConfirmation,
              style: TextStyle(color: context.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(
                l10n(ctx).chatConfirmDelete,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                final repository = ref.read(chatRepositoryProvider);
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                final messenger = ScaffoldMessenger.of(context);
                final chatId = widget.chatId;
                final threadType = _threadType;
                AppSnackbar.undoable(
                  context,
                  message: l10n(context).chatDeleteConversationUndo,
                  onUndo: () {
                    if (messenger.mounted) {
                      AppSnackbar.infoOnMessenger(
                        messenger,
                        l10n(messenger.context).chatDeleteCancelled,
                      );
                    }
                  },
                  onCommit: () async {
                    final result = await repository.deleteChat(
                      chatId,
                      threadType,
                    );
                    result.fold(
                      (failure) {
                        if (messenger.mounted) {
                          AppSnackbar.errorOnMessenger(
                            messenger,
                            localizedFailureMessage(messenger.context, failure),
                          );
                        }
                      },
                      (_) {
                        container.invalidate(chatsProvider);
                        container.invalidate(liveChatListProvider);
                        container.invalidate(archivedChatListProvider);
                        if (mounted) context.pop();
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeSheet() {
    final initialTheme =
        ref
            .read(conversationMessagesProvider(widget.chatId))
            .preference
            ?.theme ??
        'DEFAULT';
    showBrutalistSheet(
      context: context,
      title: l10n(context).chatThemeTitle,
      builder: (_) => ChatThemePicker(
        initialApiValue: initialTheme,
        onSelected: (t) async {
          final res = await ref
              .read(chatRepositoryProvider)
              .setTheme(widget.chatId, _threadType, t.apiValue);
          res.fold((_) {}, _notifier.setPreference);
        },
      ),
    );
  }
}
