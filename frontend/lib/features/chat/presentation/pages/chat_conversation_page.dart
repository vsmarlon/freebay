import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/pages/location_picker_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/attachment_bottom_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_header.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:freebay/features/chat/presentation/widgets/multi_select_toolbar.dart';
import 'package:freebay/features/chat/presentation/widgets/product_picker_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/make_offer_dialog.dart';
import 'package:freebay/features/chat/presentation/widgets/reply_composer_banner.dart';
import 'package:freebay/features/chat/presentation/widgets/typing_indicator_bubble.dart';
import 'package:freebay/features/chat/presentation/widgets/who_reacted_sheet.dart';
import 'package:freebay/shared/events/chat_event.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String chatId;
  final String orderName;
  final String? orderAvatarUrl;
  final String chatType;

  const ChatConversationPage({
    super.key,
    required this.chatId,
    required this.orderName,
    this.orderAvatarUrl,
    this.chatType = 'direct',
  });

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageKeys = <String, GlobalKey>{};
  final _selectedMessageIds = <String>{};

  List<MessageEntity> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSelecting = false;
  bool _otherUserTyping = false;
  bool _otherUserOnline = false;
  DateTime? _otherUserLastSeen;
  bool _viewOnceEnabled = false;
  String? _highlightedMessageId;
  MessageEntity? _replyTarget;
  ConversationPreference? _preference;
  Timer? _typingDebounceTimer;
  StreamSubscription<ChatEvent>? _socketSub;

  ChatThreadType get _threadType =>
      widget.chatType == 'order' ? ChatThreadType.order : ChatThreadType.direct;

  Color get _accentColor {
    final theme = ChatTheme.fromApiValue(_preference?.theme ?? 'DEFAULT');
    return Color(int.parse(theme.accentHex.replaceFirst('#', '0xFF')));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeSocket();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _socketSub?.cancel();
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

  Future<void> _loadData() async {
    final repo = ref.read(chatRepositoryProvider);
    final results = await repo.getConversation(widget.chatId);

    if (!mounted) return;

    if (results.isRight) {
      final data = results.rightOrNull;
      _messages = List.from(data?.messages ?? []);
      _preference = data?.preference;
      for (final m in _messages) {
        _messageKeys[m.id] = GlobalKey();
      }
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _subscribeSocket() {
    final ws = ref.read(chatSocketServiceProvider);
    ws.joinConversation(widget.chatId);
    _socketSub = ws.events.listen((event) {
      if (!mounted) return;
      if (event is NewMessageEvent &&
          event.message.conversationId == widget.chatId) {
        setState(() {
          // Remove any temporary message with matching content or add new
          _messages.removeWhere(
            (m) =>
                m.id.startsWith('temp-') &&
                m.content == event.message.content &&
                m.senderId == event.message.senderId,
          );
          if (!_messages.any((m) => m.id == event.message.id)) {
            _messages.add(event.message);
            _messageKeys[event.message.id] = GlobalKey();
          }
        });
        _scrollToBottom();
      } else if (event is UserTypingEvent) {
        setState(() => _otherUserTyping = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _otherUserTyping = false);
        });
      } else if (event is UserOnlineEvent) {
        setState(() => _otherUserOnline = true);
      } else if (event is UserOfflineEvent) {
        setState(() => _otherUserOnline = false);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
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
      content: text,
      type: 'TEXT',
      replyToId: replyId,
      createdAt: DateTime.now(),
      viewOnce: viewOnce,
    );

    setState(() {
      _messages.add(optimisticMessage);
      _messageKeys[tempId] = GlobalKey();
      _replyTarget = null;
      _viewOnceEnabled = false;
      _isSending = true;
    });
    _scrollToBottom();

    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.sendMessage(
      widget.chatId,
      text,
      replyToId: replyId,
      viewOnce: viewOnce,
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    result.fold((f) {
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
      });
      AppSnackbar.error(context, f.message);
    }, (_) => _scrollToBottom());
  }

  void _showMenu() {
    showBrutalistSheet(
      context: context,
      title: 'OPÇÕES',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Personalizar'),
            onTap: () {
              Navigator.pop(ctx);
              _showCustomizeSheet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(
              _preference?.isArchived == true ? 'Desarquivar' : 'Arquivar',
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final isArchived = _preference?.isArchived ?? false;
              await ref.read(archiveChatUsecaseProvider)(
                widget.chatId,
                _threadType,
                !isArchived,
              );
              if (mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }

  void _showCustomizeSheet() {
    String currentTheme = _preference?.theme ?? 'DEFAULT';
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
                  final res = await ref.read(setChatThemeUsecaseProvider)(
                    widget.chatId,
                    _threadType,
                    t.apiValue,
                  );
                  res.fold((_) {}, (p) {
                    if (mounted) {
                      setState(() => _preference = p);
                    }
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    final bgUrl = _preference?.backgroundUrl;

    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelecting) setState(() => _isSelecting = false);
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: Column(
          children: [
            if (_isSelecting)
              MultiSelectToolbar(
                selectedCount: _selectedMessageIds.length,
                onClose: () => setState(() => _isSelecting = false),
                onDelete: () async {
                  final repo = ref.read(chatRepositoryProvider);
                  for (final id in _selectedMessageIds) {
                    await repo.deleteMessage(widget.chatId, id);
                  }
                  setState(() {
                    _messages.removeWhere(
                      (m) => _selectedMessageIds.contains(m.id),
                    );
                    _selectedMessageIds.clear();
                    _isSelecting = false;
                  });
                },
                onForward: () {},
                onStar: () {},
                onShare: () {},
                onReply: () {},
              )
            else
              ChatHeader(
                name: widget.orderName,
                avatarUrl: widget.orderAvatarUrl,
                chatType: widget.chatType,
                accentColor: _accentColor,
                isOnline: _otherUserOnline,
                lastSeenAt: _otherUserLastSeen,
                onBack: () => context.pop(),
                onConfig: _showMenu,
                onInfo: () => context.push(
                  '/chat/${widget.chatId}/details',
                  extra: {
                    'name': widget.orderName,
                    'avatarUrl': widget.orderAvatarUrl,
                    'messages': _messages,
                  },
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const SkeletonPage(
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          ShimmerBlock(height: 60),
                          SizedBox(height: 12),
                          ShimmerBlock(height: 60),
                        ],
                      ),
                    )
                  : _messages.isEmpty
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
                                image: NetworkImage(bgUrl),
                                fit: BoxFit.cover,
                                opacity: 0.15,
                              ),
                            )
                          : null,
                      child: ChatMessageList(
                        scrollController: _scrollController,
                        messages: _messages,
                        currentUserId: currentUserId,
                        otherUserName: widget.orderName,
                        isDark: context.isDark,
                        accentColor: _accentColor,
                        messageKeys: _messageKeys,
                        highlightedMessageId: _highlightedMessageId,
                        isSelecting: _isSelecting,
                        selectedMessageIds: _selectedMessageIds,
                        onToggleSelection: (id) => setState(() {
                          if (_selectedMessageIds.contains(id)) {
                            _selectedMessageIds.remove(id);
                            if (_selectedMessageIds.isEmpty)
                              _isSelecting = false;
                          } else {
                            _selectedMessageIds.add(id);
                          }
                        }),
                        onEnterSelectionMode: (id) => setState(() {
                          _isSelecting = true;
                          _selectedMessageIds.add(id);
                        }),
                        onReplyTap: (id) {},
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
            if (_otherUserTyping) const TypingIndicatorBubble(),
            if (_replyTarget != null)
              ReplyComposerBanner(
                replyTo: _replyTarget!,
                currentUserId: currentUserId,
                otherUserName: widget.orderName,
                accentColor: _accentColor,
                onCancel: () => setState(() => _replyTarget = null),
              ),
            ChatInputBar(
              controller: _messageController,
              isSending: _isSending,
              viewOnceEnabled: _viewOnceEnabled,
              accentColor: _accentColor,
              onSend: _sendMessage,
              onAttachment: () => showAttachmentSheet(
                context: context,
                onMediaReady: (media) async {
                  final repo = ref.read(chatRepositoryProvider);
                  await repo.sendRichMessage(
                    conversationId: widget.chatId,
                    type: media.type,
                    attachmentUrl: media.url,
                    viewOnce: _viewOnceEnabled,
                  );
                  _loadData();
                },
                onLocationTap: () async {
                  final loc = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationPickerPage(),
                    ),
                  );
                  if (loc != null && mounted) {
                    await ref
                        .read(chatRepositoryProvider)
                        .sendRichMessage(
                          conversationId: widget.chatId,
                          type: 'LOCATION',
                          metadata: loc,
                        );
                    _loadData();
                  }
                },
                onProductTap: () => showProductPickerSheet(
                  context: context,
                  onProductSelected: (meta) async {
                    await ref
                        .read(chatRepositoryProvider)
                        .sendRichMessage(
                          conversationId: widget.chatId,
                          type: 'PRODUCT_CARD',
                          metadata: meta,
                        );
                    _loadData();
                  },
                ),
                onOfferTap: () => showDialog(
                  context: context,
                  builder: (_) => MakeOfferDialog(
                    onSendOffer: (offerData) async {
                      await ref
                          .read(chatRepositoryProvider)
                          .sendRichMessage(
                            conversationId: widget.chatId,
                            type: 'OFFER',
                            metadata: offerData,
                          );
                      _loadData();
                    },
                  ),
                ),
                onError: (e) => AppSnackbar.error(context, e),
              ),
              onViewOnceToggled: (v) => setState(() => _viewOnceEnabled = v),
            ),
          ],
        ),
      ),
    );
  }
}
