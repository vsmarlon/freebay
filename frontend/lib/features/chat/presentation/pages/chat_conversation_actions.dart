part of 'chat_conversation_page.dart';

mixin _ChatConversationActions on ConsumerState<ChatConversationPage> {
  TextEditingController get _messageController;
  ScrollController get _scrollController;
  int get _conversationGeneration;
  bool get _scrollPostFrameQueued;
  set _scrollPostFrameQueued(bool value);
  bool get _scrollAnimating;
  set _scrollAnimating(bool value);
  void _scrollToBottom([int? generation]) {
    final expectedGeneration = generation ?? _conversationGeneration;
    if (!mounted || _scrollPostFrameQueued || _scrollAnimating) return;
    _scrollPostFrameQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollPostFrameQueued = false;
      if (!mounted ||
          expectedGeneration != _conversationGeneration ||
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
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    final generation = _conversationGeneration;
    final currentUserId = ref.read(authControllerProvider).value?.id;
    final replyId = _replyTarget?.id;
    final viewOnce = _viewOnceEnabled;
    _messageController.clear();
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
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
    _notifier.addOptimistic(optimisticMessage);
    _scrollToBottom();
    final result = await ref
        .read(chatRepositoryProvider)
        .sendMessage(
          widget.chatId,
          text,
          replyToId: replyId,
          viewOnce: viewOnce,
          clientMessageId: tempId,
        );
    if (!mounted || generation != _conversationGeneration) return;
    setState(() => _isSending = false);
    result.fold(
      (f) {
        _notifier.removeByIds({tempId});
        AppSnackbar.error(context, f.message);
      },
      (sent) {
        _notifier.confirmSent(tempId, sent);
        _scrollToBottom();
        ref.read(liveChatListProvider.notifier).refreshRecent();
      },
    );
  }

  Future<void> _sendAudio(AudioRecording recording) async {
    final generation = _conversationGeneration;
    final chatId = widget.chatId;
    final replyId = _takeReplyTarget();
    setState(() {
      _isRecording = false;
      _isSending = true;
    });
    try {
      final upload = await UploadService.uploadFile(recording.file, 'chat');
      final url = upload.rightOrNull;
      if (url == null) {
        if (mounted) {
          AppSnackbar.error(
            context,
            upload.leftOrNull?.message ?? 'Erro ao enviar áudio',
          );
        }
        return;
      }
      if (!mounted || generation != _conversationGeneration) return;
      final result = await ref
          .read(chatRepositoryProvider)
          .sendRichMessage(
            conversationId: chatId,
            type: MessageType.audio,
            attachmentUrl: url,
            replyToId: replyId,
            durationMs: recording.duration.inMilliseconds,
          );
      if (!mounted || generation != _conversationGeneration) return;
      result.fold((f) => AppSnackbar.error(context, f.message), (sent) {
        _notifier.confirmSent(sent.id, sent);
        _scrollToBottom();
        ref.read(liveChatListProvider.notifier).refreshRecent();
      });
    } finally {
      try {
        await recording.file.delete();
      } catch (_) {}
      if (mounted && generation == _conversationGeneration) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendLocation({
    required Map<String, dynamic> metadata,
    required String? replyToId,
    required String clientMessageId,
  }) async {
    if (_isSending) return;
    final generation = _conversationGeneration;
    setState(() => _isSending = true);
    try {
      final result = await _notifier.sendLocation(
        metadata: metadata,
        replyToId: replyToId,
        clientMessageId: clientMessageId,
      );
      if (!mounted || generation != _conversationGeneration) return;
      result.fold(
        (failure) => AppSnackbar.error(
          context,
          failure.message,
          action: SnackBarAction(
            label: 'TENTAR NOVAMENTE',
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
      if (mounted && generation == _conversationGeneration) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendRich({
    required MessageType type,
    String? content,
    String? attachmentUrl,
    String? replyToId,
    Map<String, dynamic>? metadata,
    bool viewOnce = false,
  }) async {
    if (!mounted || _isSending) return;
    final generation = _conversationGeneration;
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
          );
      if (!mounted || generation != _conversationGeneration) return;
      result.fold((failure) => AppSnackbar.error(context, failure.message), (
        sent,
      ) {
        _notifier.confirmSent(sent.id, sent);
        _scrollToBottom();
        ref.read(liveChatListProvider.notifier).refreshRecent();
      });
    } finally {
      if (mounted && generation == _conversationGeneration) {
        setState(() => _isSending = false);
      }
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
      message: ids.length == 1
          ? 'Mensagem apagada.'
          : '${ids.length} mensagens apagadas.',
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
              'Não foi possível apagar algumas mensagens',
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
      onCustomize: _showCustomizeSheet,
      onArchive: () async {
        final isArchived = preference?.isArchived ?? false;
        final result = await ref
            .read(chatRepositoryProvider)
            .archiveChat(widget.chatId, _threadType, !isArchived);
        if (!mounted) return;
        result.fold((failure) => AppSnackbar.error(context, failure.message), (
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
      title: 'TEMA',
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
