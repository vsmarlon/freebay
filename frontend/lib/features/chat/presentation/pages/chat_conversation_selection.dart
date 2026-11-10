part of 'chat_conversation_page.dart';

mixin _ChatConversationSelectionActions on ConsumerState<ChatConversationPage> {
  Set<String> get _selectedMessageIds;
  set _isSelecting(bool value);
  set _replyTarget(MessageEntity? value);
  ConversationMessagesNotifier get _notifier;

  void _replyFromSelection() {
    if (_selectedMessageIds.length != 1) {
      AppSnackbar.info(context, 'Selecione uma mensagem para responder.');
      return;
    }
    final id = _selectedMessageIds.single;
    final messages = ref
        .read(conversationMessagesProvider(widget.chatId))
        .messages;
    MessageEntity? found;
    for (final m in messages) {
      if (m.id == id) {
        found = m;
        break;
      }
    }
    setState(() {
      _isSelecting = false;
      _selectedMessageIds.clear();
      _replyTarget = found;
    });
  }

  Future<void> _toggleStarSelected() async {
    if (_selectedMessageIds.isEmpty) return;
    final ids = _selectedMessageIds.toList();
    final starredIds = ref
        .read(conversationMessagesProvider(widget.chatId))
        .starredIds;
    final allStarred = ids.every(starredIds.contains);
    final repo = ref.read(chatRepositoryProvider);
    var failures = 0;
    for (final id in ids) {
      final currentlyStarred = starredIds.contains(id);
      if (allStarred == currentlyStarred) {
        final result = await repo.toggleStar(widget.chatId, id);
        result.fold((_) => failures++, (starred) {
          _notifier.setStarred(id, starred);
        });
      }
    }
    if (!mounted) return;
    setState(() {
      _isSelecting = false;
      _selectedMessageIds.clear();
    });
    if (failures > 0) {
      AppSnackbar.error(context, 'Não foi possível favoritar tudo.');
    } else {
      AppSnackbar.success(
        context,
        allStarred ? 'Removido dos favoritos.' : 'Adicionado aos favoritos.',
      );
    }
  }

  Future<void> _shareSelected() async {
    if (_selectedMessageIds.isEmpty) return;
    final currentUserId = ref.read(authControllerProvider).value?.id;
    final selected = ref
        .read(conversationMessagesProvider(widget.chatId))
        .messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    if (selected.isEmpty) return;
    final otherName = ref
        .read(conversationMessagesProvider(widget.chatId))
        .otherUserName;
    if (otherName == null) return;
    final lines = selected
        .map((m) {
          final who = m.senderId == currentUserId ? 'Você' : otherName;
          final when =
              '${DateUtilsCustom.formatShortDate(m.createdAt.toLocal())} ${formatMessageTime(m.createdAt)}';
          return '[$when] $who: ${m.previewText}';
        })
        .join('\n');
    await SharePlus.instance.share(ShareParams(text: lines));
    if (mounted) {
      setState(() {
        _isSelecting = false;
        _selectedMessageIds.clear();
      });
    }
  }

  void _copySelectedMessages() {
    if (_selectedMessageIds.isEmpty) return;

    final selectedMsgs = ref
        .read(conversationMessagesProvider(widget.chatId))
        .messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();

    if (selectedMsgs.isEmpty) return;

    final currentUserId = ref.read(authControllerProvider).value?.id;

    String textToCopy;
    if (selectedMsgs.length == 1) {
      final msg = selectedMsgs.first;
      if (msg.content != null && msg.content!.isNotEmpty) {
        textToCopy = msg.content!;
      } else if (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) {
        textToCopy = msg.attachmentUrl!;
      } else if (msg.type == MessageType.location && msg.metadata != null) {
        final lat = msg.metadata!['latitude'];
        final lng = msg.metadata!['longitude'];
        final address = msg.metadata!['address'] ?? '';
        textToCopy =
            'Localização: $address (https://maps.google.com/?q=$lat,$lng)';
      } else {
        textToCopy = '[Mensagem: ${msg.type.wireValue}]';
      }
    } else {
      selectedMsgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final buffer = StringBuffer();
      final otherName = ref
          .read(conversationMessagesProvider(widget.chatId))
          .otherUserName;
      if (otherName == null) return;
      for (final msg in selectedMsgs) {
        final isMe = msg.senderId == currentUserId;
        final senderName = isMe ? 'Você' : otherName;
        final timeStr = formatMessageTime(msg.createdAt);
        final content =
            msg.content ?? msg.attachmentUrl ?? '[${msg.type.wireValue}]';
        buffer.writeln('[$timeStr] $senderName: $content');
      }
      textToCopy = buffer.toString().trim();
    }

    Clipboard.setData(ClipboardData(text: textToCopy));
    final count = selectedMsgs.length;
    AppSnackbar.success(
      context,
      count == 1
          ? 'Mensagem copiada para a área de transferência'
          : '$count mensagens copiadas para a área de transferência',
    );
    setState(() {
      _isSelecting = false;
      _selectedMessageIds.clear();
    });
  }

  Future<void> _forwardSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    final ids = _selectedMessageIds.toList();
    final result = await showForwardMessageSheet(
      context: context,
      messageIds: ids,
      currentChatId: widget.chatId,
    );

    if (result == true && mounted) {
      setState(() {
        _isSelecting = false;
        _selectedMessageIds.clear();
      });
      _notifier.refresh();
    }
  }
}
