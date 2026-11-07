import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'package:freebay/features/chat/data/repositories/chat_repository.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/shared/events/chat_event.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uuid/uuid.dart';

/// Page-scoped source of truth for one conversation's server state.
///
/// The conversation page previously kept `_messages`, `_preference`,
/// `_starredIds` and the pagination cursor in `setState` fields, mutating
/// them directly with `setState` as a repaint signal. Ephemeral UI
/// (selection, reply target, highlight, typing indicator, recording,
/// submit spinner) stays in the page; everything fetched or socket-driven
/// lives here.
class ConversationMessagesState {
  final List<MessageEntity> messages;
  final ConversationPreference? preference;
  final Set<String> starredIds;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasMore;
  final bool otherUserTyping;
  final bool otherUserOnline;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatarUrl;
  final ChatThreadType? threadType;
  final String? loadError;

  const ConversationMessagesState({
    this.messages = const [],
    this.preference,
    this.starredIds = const {},
    this.isLoading = true,
    this.isLoadingOlder = false,
    this.hasMore = false,
    this.otherUserTyping = false,
    this.otherUserOnline = false,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatarUrl,
    this.threadType,
    this.loadError,
  });

  bool get hasHeader => otherUserName != null && threadType != null;

  ConversationMessagesState copyWith({
    List<MessageEntity>? messages,
    ConversationPreference? preference,
    Set<String>? starredIds,
    bool? isLoading,
    bool? isLoadingOlder,
    bool? hasMore,
    bool? otherUserTyping,
    bool? otherUserOnline,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatarUrl,
    ChatThreadType? threadType,
    String? loadError,
    bool clearLoadError = false,
  }) {
    return ConversationMessagesState(
      messages: messages ?? this.messages,
      preference: preference ?? this.preference,
      starredIds: starredIds ?? this.starredIds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMore: hasMore ?? this.hasMore,
      otherUserTyping: otherUserTyping ?? this.otherUserTyping,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      threadType: threadType ?? this.threadType,
      loadError: clearLoadError ? null : loadError ?? this.loadError,
    );
  }
}

class ConversationMessagesNotifier extends Notifier<ConversationMessagesState> {
  ConversationMessagesNotifier(this.chatId);

  final String chatId;
  String? _cursor;
  StreamSubscription<ChatEvent>? _sub;
  Timer? _typingTimer;
  int _locationSendSequence = 0;
  int _loadSequence = 0;
  final Map<String, String> _viewOnceOpeningKeys = {};
  late ChatRepository _repository;

  @override
  ConversationMessagesState build() {
    final socket = ref.read(chatSocketServiceProvider);
    _repository = ref.read(chatRepositoryProvider);
    final repository = _repository;
    ref.listen(authControllerProvider.select((auth) => auth.value?.id), (
      previous,
      next,
    ) {
      if (previous == next || !ref.mounted) return;
      for (final entry in _viewOnceOpeningKeys.entries) {
        unawaited(
          repository
              .closeViewOnce(chatId, entry.key, entry.value)
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
      _viewOnceOpeningKeys.clear();
      _cursor = null;
      _loadSequence++;
      state = const ConversationMessagesState();
      _loadFirstPage();
    });
    socket.joinConversation(chatId);
    _sub = socket.events.listen(_onEvent);
    ref.onDispose(() {
      socket.leaveConversation(chatId);
      _sub?.cancel();
      _typingTimer?.cancel();
      for (final entry in _viewOnceOpeningKeys.entries) {
        unawaited(
          repository
              .closeViewOnce(chatId, entry.key, entry.value)
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
      _viewOnceOpeningKeys.clear();
    });
    _loadFirstPage();
    return const ConversationMessagesState();
  }

  Future<void> _loadFirstPage() async {
    await _loadConversation(showLoadingError: true);
  }

  Future<void> _loadConversation({required bool showLoadingError}) async {
    final sequence = ++_loadSequence;
    final repo = ref.read(chatRepositoryProvider);
    final conversationFuture = repo.getConversation(chatId);
    final starredFuture = repo.getStarredMessages(chatId);
    final results = await conversationFuture;
    final starred = await starredFuture;
    if (!ref.mounted || sequence != _loadSequence) return;
    results.fold(
      (failure) {
        if (showLoadingError) {
          state = state.copyWith(isLoading: false, loadError: failure.message);
        }
      },
      (data) {
        _cursor = data.nextCursor;
        final uncertain = state.messages.where((message) {
          if (message.metadata?['_deliveryUncertain'] != true) return false;
          return !data.messages.any(
            (canonical) =>
                canonical.id == message.id ||
                canonical.clientMessageId == message.clientMessageId,
          );
        });
        state = state.copyWith(
          messages: [
            ..._retainOpenViewOnceMessages(data.messages),
            ...uncertain,
          ],
          preference: data.preference,
          hasMore: data.hasMore,
          isLoading: showLoadingError ? false : null,
          otherUserId: data.otherUserId,
          otherUserName: data.otherUserName,
          otherUserAvatarUrl: data.otherUserAvatarUrl,
          threadType: data.threadType,
          clearLoadError: true,
        );
      },
    );
    if (!ref.mounted || sequence != _loadSequence) return;
    starred.fold((_) {}, (messages) {
      state = state.copyWith(starredIds: {for (final m in messages) m.id});
    });
  }

  /// Silent reload (no skeleton) after sends from attachment sheets.
  Future<void> refresh() => _loadConversation(showLoadingError: false);

  Future<Either<Failure, void>> revealViewOnce(String messageId) async {
    final matchingMessages = state.messages
        .where((item) => item.id == messageId)
        .toList();
    final message = matchingMessages.isEmpty ? null : matchingMessages.first;
    final currentUserId = ref.read(authControllerProvider).value?.id;
    if (message == null ||
        !message.viewOnce ||
        currentUserId == null ||
        message.senderId == currentUserId ||
        (message.readAt != null &&
            !_viewOnceOpeningKeys.containsKey(messageId))) {
      return const Left(ServerFailure());
    }
    final openingKey = _viewOnceOpeningKeys.putIfAbsent(
      messageId,
      () => const Uuid().v4(),
    );
    final repository = _repository;
    final result = await repository.openViewOnce(chatId, messageId, openingKey);
    if (!ref.mounted) {
      unawaited(
        repository
            .closeViewOnce(chatId, messageId, openingKey)
            .then<void>((_) {}, onError: (Object _) {}),
      );
      return const Right(null);
    }
    if (_viewOnceOpeningKeys[messageId] != openingKey) {
      unawaited(
        repository
            .closeViewOnce(chatId, messageId, openingKey)
            .then<void>((_) {}, onError: (Object _) {}),
      );
      return const Right(null);
    }
    return result.fold<Either<Failure, void>>(Left.new, (opened) {
      state = state.copyWith(
        messages: [
          for (final item in state.messages)
            if (item.id == messageId)
              item.copyWith(
                attachmentUrl: opened.mediaUrl,
                readAt: opened.readAt,
                deliveredAt: item.deliveredAt ?? opened.readAt,
              )
            else
              item,
        ],
      );
      return const Right(null);
    });
  }

  String? viewOnceOpeningKey(String messageId) =>
      _viewOnceOpeningKeys[messageId];

  List<MessageEntity> _retainOpenViewOnceMessages(
    List<MessageEntity> incoming,
  ) => [
    for (final message in incoming)
      if (_viewOnceOpeningKeys.containsKey(message.id) &&
          message.deletedAt == null)
        _openedMessage(message)
      else
        message,
  ];

  MessageEntity _openedMessage(MessageEntity incoming) {
    for (final existing in state.messages) {
      if (existing.id == incoming.id && existing.readAt != null) {
        return incoming.copyWith(
          attachmentUrl: existing.attachmentUrl,
          readAt: existing.readAt,
          deliveredAt: existing.deliveredAt,
        );
      }
    }
    return incoming;
  }

  void closeViewOnce(String messageId) {
    final openingKey = _viewOnceOpeningKeys.remove(messageId);
    if (openingKey == null) return;
    if (ref.mounted) {
      state = state.copyWith(
        messages: [
          for (final message in state.messages)
            if (message.id == messageId)
              message.copyWith(attachmentUrl: null)
            else
              message,
        ],
      );
    }
    unawaited(
      _repository
          .closeViewOnce(chatId, messageId, openingKey)
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  Future<Either<Failure, MessageEntity>> sendLocation({
    required Map<String, dynamic> metadata,
    String? replyToId,
    String? clientMessageId,
    CancelToken? cancelToken,
  }) async {
    final operationId =
        clientMessageId ??
        'location-${DateTime.now().microsecondsSinceEpoch}-${_locationSendSequence++}';
    final result = await ref
        .read(chatRepositoryProvider)
        .sendRichMessage(
          conversationId: chatId,
          clientMessageId: operationId,
          type: MessageType.location,
          replyToId: replyToId,
          metadata: metadata,
          cancelToken: cancelToken,
        );
    if (!ref.mounted) return result;
    result.fold((_) {}, (message) => confirmSent(operationId, message));
    return result;
  }

  Future<void> loadOlder() async {
    if (state.isLoadingOlder || !state.hasMore || _cursor == null) return;
    state = state.copyWith(isLoadingOlder: true);
    final repo = ref.read(chatRepositoryProvider);
    final results = await repo.getConversation(chatId, cursor: _cursor);
    if (!ref.mounted) return;
    results.fold((_) => state = state.copyWith(isLoadingOlder: false), (data) {
      _cursor = data.nextCursor;
      state = state.copyWith(
        messages: [
          ..._retainOpenViewOnceMessages(data.messages),
          ...state.messages,
        ],
        hasMore: data.hasMore,
        isLoadingOlder: false,
      );
    });
  }

  void _onEvent(ChatEvent event) {
    if (!ref.mounted) return;
    if (event is NewMessageEvent) {
      if (event.message.conversationId != chatId) return;
      applyIncoming(event.message);
    } else if (event is ReactionUpdatedEvent) {
      applyReactions(event.messageId, event.reactions);
    } else if (event is MessageDeletedEvent) {
      removeByIds({event.messageId});
    } else if (event is UserTypingEvent) {
      _typingTimer?.cancel();
      state = state.copyWith(otherUserTyping: true);
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (ref.mounted) state = state.copyWith(otherUserTyping: false);
      });
    } else if (event is UserStoppedTypingEvent) {
      _typingTimer?.cancel();
      state = state.copyWith(otherUserTyping: false);
    } else if (event is UserOnlineEvent) {
      state = state.copyWith(otherUserOnline: true);
    } else if (event is UserOfflineEvent) {
      state = state.copyWith(otherUserOnline: false);
    } else if (event is MessagesReadEvent) {
      final currentUserId = ref.read(authControllerProvider).value?.id;
      if (event.conversationId == chatId && event.readerId != currentUserId) {
        unawaited(refresh());
      }
    } else if (event is ChatReconnectedEvent) {
      unawaited(refresh());
    }
  }

  /// Merges a socket message, replacing the optimistic temp on id match.
  void applyIncoming(MessageEntity incoming) {
    final messages = List<MessageEntity>.from(state.messages)
      ..removeWhere(
        (m) =>
            m.id == incoming.id ||
            (incoming.clientMessageId != null &&
                m.id == incoming.clientMessageId),
      )
      ..add(incoming);
    state = state.copyWith(messages: messages);
  }

  void addOptimistic(MessageEntity message) {
    state = state.copyWith(
      messages: [
        ...state.messages.where(
          (current) =>
              current.id != message.id &&
              (message.clientMessageId == null ||
                  current.clientMessageId != message.clientMessageId),
        ),
        message,
      ],
    );
  }

  void markDeliveryUncertain(String messageId) {
    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          if (message.id == messageId)
            message.copyWith(
              metadata: {...?message.metadata, '_deliveryUncertain': true},
            )
          else
            message,
      ],
    );
  }

  void confirmSent(String tempId, MessageEntity sent) {
    final messages = List<MessageEntity>.from(state.messages)
      ..removeWhere(
        (m) =>
            m.id == tempId ||
            m.id == sent.id ||
            (sent.clientMessageId != null &&
                m.clientMessageId == sent.clientMessageId),
      )
      ..add(sent);
    state = state.copyWith(messages: messages);
  }

  void removeByIds(Set<String> ids) {
    state = state.copyWith(
      messages: state.messages.where((m) => !ids.contains(m.id)).toList(),
    );
  }

  void insertMessage(int index, MessageEntity message) {
    final messages = List<MessageEntity>.from(state.messages);
    messages.insert(index.clamp(0, messages.length), message);
    state = state.copyWith(messages: messages);
  }

  void applyReactions(String messageId, List<MessageReactionEntity> reactions) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == messageId) m.copyWith(reactions: reactions) else m,
      ],
    );
  }

  void setStarred(String messageId, bool starred) {
    final starredIds = Set<String>.from(state.starredIds);
    if (starred) {
      starredIds.add(messageId);
    } else {
      starredIds.remove(messageId);
    }
    state = state.copyWith(starredIds: starredIds);
  }

  void setPreference(ConversationPreference preference) {
    state = state.copyWith(preference: preference);
  }
}

final conversationMessagesProvider = NotifierProvider.autoDispose
    .family<ConversationMessagesNotifier, ConversationMessagesState, String>(
      ConversationMessagesNotifier.new,
    );
