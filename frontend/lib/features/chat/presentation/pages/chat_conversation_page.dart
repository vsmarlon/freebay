import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/audio_recorder_bar.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_attachment_flow.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_conversation_body.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_conversation_composer.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_conversation_header.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_theme_picker.dart';
import 'package:freebay/features/chat/presentation/widgets/forward_message_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/who_reacted_sheet.dart';
import 'package:freebay/features/chat/presentation/widgets/conversation_menu.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/shared/utils/date_utils.dart';

part 'chat_conversation_selection.dart';
part 'chat_conversation_lifecycle.dart';
part 'chat_conversation_actions.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatConversationPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage>
    with
        _ChatConversationLifecycle,
        _ChatConversationActions,
        _ChatConversationSelectionActions {
  @override
  final _messageController = TextEditingController();
  @override
  final _scrollController = ScrollController();
  @override
  final _messageKeys = <String, GlobalKey>{};
  ProviderSubscription<List<MessageEntity>>? _messageSubscription;
  @override
  final _selectedMessageIds = <String>{};

  // Ephemeral UI only. Server state (messages, preference, starred, cursor,
  // typing/presence) lives in conversationMessagesProvider(widget.chatId).
  @override
  bool _isSending = false;
  @override
  bool _isSelecting = false;
  @override
  bool _viewOnceEnabled = false;
  @override
  bool _isRecording = false;
  @override
  String? _highlightedMessageId;
  @override
  MessageEntity? _replyTarget;
  @override
  Timer? _typingDebounceTimer;
  @override
  bool _scrollPostFrameQueued = false;
  @override
  bool _scrollAnimating = false;
  @override
  int _conversationGeneration = 0;

  @override
  ConversationMessagesNotifier get _notifier =>
      ref.read(conversationMessagesProvider(widget.chatId).notifier);

  @override
  ChatThreadType get _threadType =>
      ref.read(conversationMessagesProvider(widget.chatId)).threadType ??
      ChatThreadType.direct;

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
    _bindMessageListener(widget.chatId);
  }

  void _bindMessageListener(String chatId) {
    final generation = ++_conversationGeneration;
    _messageSubscription?.close();
    _messageSubscription = ref.listenManual<List<MessageEntity>>(
      conversationMessagesProvider(chatId).select((state) => state.messages),
      (previous, next) {
        if (!mounted || generation != _conversationGeneration) return;
        final previousMessages = previous ?? const <MessageEntity>[];
        final previousIds = {for (final m in previousMessages) m.id};
        final appended =
            next.length > previousMessages.length &&
            next
                .take(previousMessages.length)
                .every((m) => previousIds.contains(m.id));
        if (appended) _scrollToBottom(generation);
        if (previousMessages != next) _syncMessageKeys(next);
      },
    );
  }

  @override
  void didUpdateWidget(covariant ChatConversationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId == widget.chatId) return;

    _messageSubscription?.close();
    _messageSubscription = null;
    _messageKeys.clear();
    _selectedMessageIds.clear();
    _isSelecting = false;
    _viewOnceEnabled = false;
    _isRecording = false;
    _isSending = false;
    _highlightedMessageId = null;
    _replyTarget = null;
    _typingDebounceTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.clear();
    _messageController.addListener(_onTextChanged);
    _scrollPostFrameQueued = false;
    _scrollAnimating = false;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _bindMessageListener(widget.chatId);
  }

  @override
  void dispose() {
    _messageSubscription?.close();
    _typingDebounceTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMessages = ref
        .read(conversationMessagesProvider(widget.chatId))
        .messages;
    if (_messageKeys.isEmpty && currentMessages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncMessageKeys(currentMessages);
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
              Consumer(
                builder: (context, ref, _) {
                  final header = ref.watch(
                    conversationMessagesProvider(widget.chatId).select(
                      (state) => (
                        hasHeader: state.hasHeader,
                        loadError: state.loadError,
                        theme: state.preference?.theme,
                        name: state.otherUserName,
                        avatarUrl: state.otherUserAvatarUrl,
                        chatType: state.threadType,
                        isOnline: state.otherUserOnline,
                      ),
                    ),
                  );
                  return ChatConversationHeader(
                    isSelecting: _isSelecting,
                    selectedCount: _selectedMessageIds.length,
                    hasHeader: header.hasHeader,
                    loadError: header.loadError,
                    name: header.name ?? '',
                    avatarUrl: header.avatarUrl,
                    chatType: header.chatType ?? ChatThreadType.direct,
                    accentColor: _accentColor,
                    isOnline: header.isOnline,
                    onBack: () => context.pop(),
                    onConfig: _showMenu,
                    onInfo: () =>
                        context.push(AppRoutes.chatDetailsPath(widget.chatId)),
                    onRetry: () => _notifier.refresh(),
                    onCloseSelection: () =>
                        setState(() => _isSelecting = false),
                    onCopy: _copySelectedMessages,
                    onForward: _forwardSelectedMessages,
                    onDelete: _deleteSelectedMessages,
                    onReply: _replyFromSelection,
                    onStar: _toggleStarSelected,
                    onShare: _shareSelected,
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final body = ref.watch(
                    conversationMessagesProvider(widget.chatId).select(
                      (state) => (
                        messages: state.messages,
                        theme: state.preference?.theme,
                        bgUrl: state.preference?.backgroundUrl,
                        hasHeader: state.hasHeader,
                        loadError: state.loadError,
                        otherUserName: state.otherUserName,
                        starredIds: state.starredIds,
                      ),
                    ),
                  );
                  final currentUserId = ref.watch(
                    authControllerProvider.select((state) => state.value?.id),
                  );
                  return ChatConversationBody(
                    scrollController: _scrollController,
                    messages: body.messages,
                    bgUrl: body.bgUrl,
                    hasHeader: body.hasHeader,
                    loadError: body.loadError,
                    currentUserId: currentUserId,
                    otherUserName: body.otherUserName ?? '',
                    accentColor: _accentColor,
                    messageKeys: _messageKeys,
                    highlightedMessageId: _highlightedMessageId,
                    starredIds: body.starredIds,
                    isSelecting: _isSelecting,
                    selectedMessageIds: _selectedMessageIds,
                    onLoadMore: _notifier.loadOlder,
                    onRetry: () => _notifier.refresh(),
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
                    onSwipeToReply: (msg) => setState(() => _replyTarget = msg),
                    onReactionTap: (msgId, emoji) => ref
                        .read(chatRepositoryProvider)
                        .reactToMessage(widget.chatId, msgId, emoji),
                    onReactionLongPress: (msg, emoji) => showModalBottomSheet(
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
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final composer = ref.watch(
                    conversationMessagesProvider(widget.chatId).select(
                      (state) => (
                        otherUserTyping: state.otherUserTyping,
                        theme: state.preference?.theme,
                        otherUserName: state.otherUserName,
                      ),
                    ),
                  );
                  final currentUserId = ref.watch(
                    authControllerProvider.select((state) => state.value?.id),
                  );
                  return ChatConversationComposer(
                    otherUserTyping: composer.otherUserTyping,
                    replyTarget: _replyTarget,
                    currentUserId: currentUserId,
                    otherUserName: composer.otherUserName,
                    accentColor: _accentColor,
                    isRecording: _isRecording,
                    messageController: _messageController,
                    isSending: _isSending,
                    viewOnceEnabled: _viewOnceEnabled,
                    onCancelReply: () => setState(() => _replyTarget = null),
                    onSendAudio: _sendAudio,
                    onCancelRecording: () =>
                        setState(() => _isRecording = false),
                    onSend: _sendMessage,
                    onRecordAudio: () => setState(() => _isRecording = true),
                    onAttachment: () => showConversationAttachmentSheet(
                      context: context,
                      takeReplyTarget: _takeReplyTarget,
                      sendRich: _sendRich,
                      sendLocation: _sendLocation,
                      showError: (e) => AppSnackbar.error(context, e),
                    ),
                    onViewOnceToggled: (v) =>
                        setState(() => _viewOnceEnabled = v),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
