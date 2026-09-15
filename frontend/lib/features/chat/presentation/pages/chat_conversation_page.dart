import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/pages/location_picker_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/attachment_bottom_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/audio_recorder_bar.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_header.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_media_composer.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_video_composer.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:freebay/features/chat/presentation/widgets/multi_select_toolbar.dart';
import 'package:freebay/features/chat/presentation/widgets/forward_message_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/product_picker_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/make_offer_dialog.dart';
import 'package:freebay/features/chat/presentation/widgets/reply_composer_banner.dart';
import 'package:freebay/features/chat/presentation/widgets/typing_indicator_bubble.dart';
import 'package:freebay/features/chat/presentation/widgets/who_reacted_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/conversation_menu.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/utils/date_utils.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatConversationPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageKeys = <String, GlobalKey>{};
  final _selectedMessageIds = <String>{};

  // Ephemeral UI only. Server state (messages, preference, starred, cursor,
  // typing/presence) lives in conversationMessagesProvider(widget.chatId).
  bool _isSending = false;
  bool _isSelecting = false;
  bool _viewOnceEnabled = false;
  bool _isRecording = false;
  String? _highlightedMessageId;
  MessageEntity? _replyTarget;
  Timer? _typingDebounceTimer;
  bool _scrollPostFrameQueued = false;
  bool _scrollAnimating = false;

  ConversationMessagesNotifier get _notifier =>
      ref.read(conversationMessagesProvider(widget.chatId).notifier);

  ChatThreadType get _threadType =>
      ref.read(conversationMessagesProvider(widget.chatId)).threadType ==
          'ORDER'
      ? ChatThreadType.order
      : ChatThreadType.direct;

  Color get _accentColor {
    final theme = ChatTheme.fromApiValue(
      ref.read(conversationMessagesProvider(widget.chatId)).preference?.theme ??
          'DEFAULT',
    );
    return Color(int.parse(theme.accentHex.replaceFirst('#', '0xFF')));
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final ws = ref.read(chatSocketServiceProvider);
      ws.sendTyping(widget.chatId);
    });
  }

  void _scrollToBottom() {
    if (!mounted || _scrollPostFrameQueued || _scrollAnimating) return;
    _scrollPostFrameQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollPostFrameQueued = false;
      if (!mounted ||
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

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

    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.sendMessage(
      widget.chatId,
      text,
      replyToId: replyId,
      viewOnce: viewOnce,
      clientMessageId: tempId,
    );

    if (!mounted) return;
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

  String? _takeReplyTarget() {
    final replyId = _replyTarget?.id;
    if (replyId != null && mounted) setState(() => _replyTarget = null);
    return replyId;
  }

  Future<void> _scrollToQuoted(String id) async {
    final ctx = _messageKeys[id]?.currentContext;
    if (ctx == null) return;
    setState(() => _highlightedMessageId = id);
    await Scrollable.ensureVisible(
      ctx,
      duration: AppMotion.enter,
      curve: AppMotion.enterCurve,
      alignment: 0.5,
    );
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _highlightedMessageId == id) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  void _replyFromSelection() {
    if (_selectedMessageIds.length != 1) {
      AppSnackbar.info(context, 'Selecione uma mensagem para responder.');
      return;
    }
    final id = _selectedMessageIds.single;
    final messages = ref
        .read(conversationMessagesProvider(widget.chatId))
        .messages;
    final found = messages.where((m) => m.id == id).toList();
    setState(() {
      _isSelecting = false;
      _selectedMessageIds.clear();
      _replyTarget = found.isEmpty ? null : found.first;
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

  Future<void> _sendAudio(AudioRecording recording) async {
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
      final result = await ref
          .read(chatRepositoryProvider)
          .sendRichMessage(
            conversationId: widget.chatId,
            type: 'AUDIO',
            attachmentUrl: url,
            replyToId: replyId,
            durationMs: recording.duration.inMilliseconds,
          );
      if (!mounted) return;
      result.fold((f) => AppSnackbar.error(context, f.message), (sent) {
        _notifier.addOptimistic(sent);
        _scrollToBottom();
      });
      _notifier.refresh();
    } finally {
      try {
        await recording.file.delete();
      } catch (_) {}
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendLocation({
    required Map<String, dynamic> metadata,
    required String? replyToId,
    required String clientMessageId,
  }) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      final result = await _notifier.sendLocation(
        metadata: metadata,
        replyToId: replyToId,
        clientMessageId: clientMessageId,
      );
      if (!mounted) return;
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
        (_) => _notifier.refresh(),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
    String currentTheme =
        ref
            .read(conversationMessagesProvider(widget.chatId))
            .preference
            ?.theme ??
        'DEFAULT';
    showBrutalistSheet(
      context: context,
      title: 'TEMA',
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            children: ChatTheme.values.map((t) {
              final isSelected = t.apiValue == currentTheme;
              return GestureDetector(
                onTap: () async {
                  setSheetState(() => currentTheme = t.apiValue);
                  final res = await ref
                      .read(chatRepositoryProvider)
                      .setTheme(widget.chatId, _threadType, t.apiValue);
                  res.fold((_) {}, (p) {
                    _notifier.setPreference(p);
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(t.accentHex.replaceFirst('#', '0xFF')),
                    ),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
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
      } else if (msg.type == 'LOCATION' && msg.metadata != null) {
        final lat = msg.metadata!['latitude'];
        final lng = msg.metadata!['longitude'];
        final address = msg.metadata!['address'] ?? '';
        textToCopy =
            'Localização: $address (https://maps.google.com/?q=$lat,$lng)';
      } else {
        textToCopy = '[Mensagem: ${msg.type}]';
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
        final content = msg.content ?? msg.attachmentUrl ?? '[${msg.type}]';
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

  void _syncMessageKeys(List<MessageEntity> messages) {
    var changed = false;
    for (final m in messages) {
      if (!_messageKeys.containsKey(m.id)) {
        _messageKeys[m.id] = GlobalKey();
        changed = true;
      }
    }
    final ids = {for (final m in messages) m.id};
    final stale = _messageKeys.keys.where((id) => !ids.contains(id)).toList();
    for (final id in stale) {
      _messageKeys.remove(id);
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    final conv = ref.watch(conversationMessagesProvider(widget.chatId));
    final messages = conv.messages;
    final bgUrl = conv.preference?.backgroundUrl;

    // Socket joins land in the provider; scroll when new messages arrive.
    // Keys are synced here (outside the widget tree) so itemBuilder never
    // creates GlobalKeys during build.
    ref.listen(conversationMessagesProvider(widget.chatId), (prev, next) {
      final previous = prev?.messages ?? const <MessageEntity>[];
      final appended =
          next.messages.length > previous.length &&
          next.messages
              .take(previous.length)
              .map((message) => message.id)
              .toList()
              .every((id) => previous.any((message) => message.id == id));
      if (appended) {
        _scrollToBottom();
      }
      if (prev?.messages != next.messages) {
        _syncMessageKeys(next.messages);
      }
    });

    if (_messageKeys.isEmpty && messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncMessageKeys(messages);
      });
    }

    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelecting) setState(() => _isSelecting = false);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Column(
            children: [
              if (_isSelecting)
                MultiSelectToolbar(
                  selectedCount: _selectedMessageIds.length,
                  onClose: () => setState(() => _isSelecting = false),
                  onCopy: _copySelectedMessages,
                  onForward: _forwardSelectedMessages,
                  onDelete: () {
                    final ids = Set<String>.from(_selectedMessageIds);
                    final removed = messages
                        .where((m) => ids.contains(m.id))
                        .toList();
                    final indexes = {
                      for (final m in removed) m.id: messages.indexOf(m),
                    };
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
                        final current = ref
                            .read(conversationMessagesProvider(widget.chatId))
                            .messages;
                        for (final m in removed) {
                          _notifier.insertMessage(
                            (indexes[m.id] ?? current.length),
                            m,
                          );
                        }
                      },
                      onCommit: () async {
                        final repo = ref.read(chatRepositoryProvider);
                        for (final id in ids) {
                          await repo.deleteMessage(widget.chatId, id);
                        }
                      },
                    );
                  },
                  onReply: _replyFromSelection,
                  onStar: _toggleStarSelected,
                  onShare: _shareSelected,
                )
              else if (conv.loadError != null && !conv.hasHeader)
                ChatHeader(
                  name: '',
                  chatType: 'direct',
                  accentColor: _accentColor,
                  hasError: true,
                  onBack: () => context.pop(),
                  onConfig: () {},
                  onRetry: () => _notifier.refresh(),
                )
              else if (!conv.hasHeader)
                ChatHeader(
                  name: '',
                  chatType: 'direct',
                  accentColor: _accentColor,
                  isLoading: true,
                  onBack: () => context.pop(),
                  onConfig: () {},
                )
              else
                ChatHeader(
                  name: conv.otherUserName ?? '',
                  avatarUrl: conv.otherUserAvatarUrl,
                  chatType: conv.threadType ?? 'direct',
                  accentColor: _accentColor,
                  isOnline: conv.otherUserOnline,
                  onBack: () => context.pop(),
                  onConfig: _showMenu,
                  onInfo: () =>
                      context.push(AppRoutes.chatDetailsPath(widget.chatId)),
                ),
              Expanded(
                child: !conv.hasHeader
                    ? (conv.loadError != null
                          ? EmptyState.error(
                              message: conv.loadError,
                              onRetry: () => _notifier.refresh(),
                            )
                          : const SkeletonPage(
                              child: Column(
                                children: [
                                  SizedBox(height: 16),
                                  ShimmerBlock(height: 60),
                                  SizedBox(height: 12),
                                  ShimmerBlock(height: 60),
                                ],
                              ),
                            ))
                    : messages.isEmpty
                    ? const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'NENHUMA MENSAGEM',
                        subtitle:
                            'Envie a primeira mensagem para iniciar a conversa.',
                      )
                    : Container(
                        decoration: bgUrl != null && bgUrl.isNotEmpty
                            ? BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    bgUrl,
                                    headers: mediaAuthHeaders(bgUrl),
                                  ),
                                  fit: BoxFit.cover,
                                  opacity: 0.15,
                                ),
                              )
                            : null,
                        child: InfiniteScrollListener(
                          edge: ScrollEdge.start,
                          onLoadMore: _notifier.loadOlder,
                          child: ChatMessageList(
                            scrollController: _scrollController,
                            messages: messages,
                            currentUserId: currentUserId,
                            otherUserName: conv.otherUserName ?? '',
                            isDark: context.isDark,
                            accentColor: _accentColor,
                            messageKeys: _messageKeys,
                            highlightedMessageId: _highlightedMessageId,
                            starredIds: conv.starredIds,
                            isSelecting: _isSelecting,
                            selectedMessageIds: _selectedMessageIds,
                            onToggleSelection: (id) => setState(() {
                              if (_selectedMessageIds.contains(id)) {
                                _selectedMessageIds.remove(id);
                                if (_selectedMessageIds.isEmpty) {
                                  _isSelecting = false;
                                }
                              } else {
                                _selectedMessageIds.add(id);
                              }
                            }),
                            onEnterSelectionMode: (id) => setState(() {
                              _isSelecting = true;
                              _selectedMessageIds.add(id);
                            }),
                            onReplyTap: _scrollToQuoted,
                            onSwipeToReply: (msg) =>
                                setState(() => _replyTarget = msg),
                            onReactionTap: (msgId, emoji) => ref
                                .read(chatRepositoryProvider)
                                .reactToMessage(widget.chatId, msgId, emoji),
                            onReactionLongPress: (msg, emoji) =>
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => WhoReactedSheet(
                                    reactions: msg.reactions,
                                    initialEmoji: emoji,
                                  ),
                                ),
                            onViewOnceReveal: (msgId) => ref
                                .read(chatRepositoryProvider)
                                .markAsRead(widget.chatId),
                          ),
                        ),
                      ),
              ),
              if (conv.otherUserTyping) const TypingIndicatorBubble(),
              if (_replyTarget != null && conv.otherUserName != null)
                ReplyComposerBanner(
                  replyTo: _replyTarget!,
                  currentUserId: currentUserId,
                  otherUserName: conv.otherUserName ?? '',
                  accentColor: _accentColor,
                  onCancel: () => setState(() => _replyTarget = null),
                ),
              if (_isRecording)
                AudioRecorderBar(
                  onSend: _sendAudio,
                  onCancel: () => setState(() => _isRecording = false),
                )
              else
                ChatInputBar(
                  controller: _messageController,
                  isSending: _isSending,
                  viewOnceEnabled: _viewOnceEnabled,
                  accentColor: _accentColor,
                  onSend: _sendMessage,
                  onRecordAudio: () => setState(() => _isRecording = true),
                  onAttachment: () => showAttachmentSheet(
                    context: context,
                    onMediaReady: (attachment) async {
                      final replyId = _takeReplyTarget();
                      await ref
                          .read(chatRepositoryProvider)
                          .sendRichMessage(
                            conversationId: widget.chatId,
                            type: attachment.type,
                            attachmentUrl: attachment.url,
                            replyToId: replyId,
                          );
                      await _notifier.refresh();
                    },
                    returnRawFile: true,
                    onRawImage: (xfile) async {
                      final bytes = await xfile.readAsBytes();
                      if (!context.mounted) return;
                      await showChatMediaComposer(
                        context: context,
                        imageBytes: bytes,
                        onSend:
                            ({
                              required attachmentUrl,
                              required type,
                              caption,
                              required viewOnce,
                            }) async {
                              final replyId = _takeReplyTarget();
                              await ref
                                  .read(chatRepositoryProvider)
                                  .sendRichMessage(
                                    conversationId: widget.chatId,
                                    content: caption,
                                    type: type,
                                    attachmentUrl: attachmentUrl,
                                    replyToId: replyId,
                                    viewOnce: viewOnce,
                                  );
                              _notifier.refresh();
                            },
                      );
                    },
                    onRawVideo: (xfile) => showChatVideoComposer(
                      context: context,
                      videoFile: File(xfile.path),
                      onSend:
                          ({
                            required attachmentUrl,
                            required type,
                            caption,
                            required viewOnce,
                          }) async {
                            final replyId = _takeReplyTarget();
                            await ref
                                .read(chatRepositoryProvider)
                                .sendRichMessage(
                                  conversationId: widget.chatId,
                                  content: caption,
                                  type: type,
                                  attachmentUrl: attachmentUrl,
                                  replyToId: replyId,
                                  viewOnce: viewOnce,
                                );
                            await _notifier.refresh();
                          },
                    ),
                    onLocationTap: () async {
                      final loc = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocationPickerPage(),
                        ),
                      );
                      if (loc != null && mounted) {
                        final replyId = _takeReplyTarget();
                        await _sendLocation(
                          metadata: loc,
                          replyToId: replyId,
                          clientMessageId:
                              'location-${DateTime.now().microsecondsSinceEpoch}',
                        );
                      }
                    },
                    onProductTap: () => showProductPickerSheet(
                      context: context,
                      onProductSelected: (meta) async {
                        final replyId = _takeReplyTarget();
                        await ref
                            .read(chatRepositoryProvider)
                            .sendRichMessage(
                              conversationId: widget.chatId,
                              type: 'PRODUCT_CARD',
                              replyToId: replyId,
                              metadata: meta,
                            );
                        _notifier.refresh();
                      },
                    ),
                    onOfferTap: () => showDialog(
                      context: context,
                      builder: (_) => MakeOfferDialog(
                        onSendOffer: (offerData) async {
                          final replyId = _takeReplyTarget();
                          await ref
                              .read(chatRepositoryProvider)
                              .sendRichMessage(
                                conversationId: widget.chatId,
                                type: 'OFFER',
                                replyToId: replyId,
                                metadata: offerData,
                              );
                          _notifier.refresh();
                        },
                      ),
                    ),
                    onError: (e) => AppSnackbar.error(context, e),
                  ),
                  onViewOnceToggled: (v) =>
                      setState(() => _viewOnceEnabled = v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
