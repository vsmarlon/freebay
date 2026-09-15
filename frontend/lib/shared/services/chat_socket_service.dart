import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/events/chat_event.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';

/// A pending message that was queued while the socket was offline.
class _OutboxEntry {
  final String conversationId;
  final String content;
  final String? replyToId;
  final bool viewOnce;

  const _OutboxEntry({
    required this.conversationId,
    required this.content,
    this.replyToId,
    this.viewOnce = false,
  });

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'conversationId': conversationId,
      'content': content,
      if (replyToId != null) 'replyToId': replyToId,
      if (viewOnce) 'viewOnce': true,
    };
  }
}

/// Manages the Socket.IO connection for real-time chat.
///
/// Offline Outbox Pattern:
///   Messages sent while disconnected (socket not ready OR device offline)
///   are queued in [_outboxQueue]. They are flushed automatically when:
///     1. The socket reconnects (`onConnect` fires), OR
///     2. Network connectivity is restored (via [connectivity_plus]).
class ChatSocketService {
  io.Socket? _socket;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _eventsController = StreamController<ChatEvent>.broadcast();

  Timer? _reconnectTimer;

  /// Internal memory queue for messages sent while offline.
  final List<_OutboxEntry> _outboxQueue = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get presenceStream => _presenceController.stream;
  Stream<ChatEvent> get events => _eventsController.stream;

  String get _wsUrl {
    final apiUrl = AppConfig.apiBaseUrl;
    return apiUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }

  // ── Connection management ────────────────────────────────────────────────

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await StorageService.getToken();
    if (token == null) return;

    _socket = io.io(
      '$_wsUrl/chat',
      io.OptionBuilder()
          .setAuth({'token': token})
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _reconnectTimer?.cancel();
        _flushOutbox();
      })
      ..onConnectError((error) {
        if (error is Map &&
            error['message']?.toString().contains('jwt') == true) {
          _reconnectTimer?.cancel();
          disconnect();
        }
      })
      ..onDisconnect((reason) {
        if (reason != null && reason.contains('jwt') ||
            reason == 'io server disconnect') {
          disconnect();
        }
      })
      ..on('new_message', (data) {
        if (data is Map) {
          final payload = Map<String, dynamic>.from(data);
          _messageController.add(payload);
          try {
            _eventsController.add(
              NewMessageEvent(MessageEntity.fromJson(payload)),
            );
          } catch (e) {
            debugPrint('[chat-socket] dropped malformed new_message: $e');
          }
        }
      })
      ..on('reaction_updated', (data) {
        if (data is Map) {
          final payload = Map<String, dynamic>.from(data);
          final messageId = payload['messageId'] as String? ?? '';
          final reactions =
              (payload['reactions'] as List?)
                  ?.whereType<Map>()
                  .map((e) {
                    try {
                      return MessageReactionEntity.fromJson(
                        Map<String, dynamic>.from(e),
                      );
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<MessageReactionEntity>()
                  .toList() ??
              [];
          _eventsController.add(ReactionUpdatedEvent(messageId, reactions));
        }
      })
      ..on('message_deleted', (data) {
        if (data is Map<String, dynamic>) {
          final messageId = data['messageId'] as String? ?? '';
          _eventsController.add(MessageDeletedEvent(messageId));
        }
      })
      ..on('user_typing', (data) {
        if (data is Map<String, dynamic>) {
          _typingController.add({...data, 'typing': true});
          final userId = data['userId'] as String?;
          if (userId != null) {
            _eventsController.add(UserTypingEvent(userId));
          }
        }
      })
      ..on('user_stopped_typing', (data) {
        if (data is Map<String, dynamic>) {
          _typingController.add({...data, 'typing': false});
          final userId = data['userId'] as String?;
          if (userId != null) {
            _eventsController.add(UserStoppedTypingEvent(userId));
          }
        }
      })
      ..on('user_online', (data) {
        if (data is Map<String, dynamic>) {
          _presenceController.add({...data, 'online': true});
          final userId = data['userId'] as String?;
          if (userId != null) {
            _eventsController.add(UserOnlineEvent(userId));
          }
        }
      })
      ..on('user_offline', (data) {
        if (data is Map<String, dynamic>) {
          _presenceController.add({...data, 'online': false});
          final userId = data['userId'] as String?;
          if (userId != null) {
            _eventsController.add(UserOfflineEvent(userId));
          }
        }
      });

    _socket!.connect();

    // Watch for network recovery and flush outbox when connectivity returns.
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _socket?.dispose();
    _socket = null;
  }

  Future<void> reconnectWithFreshToken() async {
    disconnect();
    await connect();
  }

  // ── Outbox helpers ───────────────────────────────────────────────────────

  /// Attempts to flush all queued outbox messages in order.
  void _flushOutbox() {
    if (_outboxQueue.isEmpty) return;
    if (_socket?.connected != true) return;

    final pending = List<_OutboxEntry>.from(_outboxQueue);
    _outboxQueue.clear();

    for (final entry in pending) {
      _socket!.emit('send_message', entry.toPayload());
    }
  }

  /// Called whenever device connectivity changes.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (hasNetwork && _socket?.connected == true) {
      _flushOutbox();
    } else if (hasNetwork && _socket?.connected != true) {
      // Network returned but socket dropped — attempt reconnect.
      reconnectWithFreshToken();
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', {'conversationId': conversationId});
  }

  /// Sends a message immediately when connected; queues it otherwise.
  void sendMessage(
    String conversationId,
    String content, {
    String? replyToId,
    bool viewOnce = false,
  }) {
    final entry = _OutboxEntry(
      conversationId: conversationId,
      content: content,
      replyToId: replyToId,
      viewOnce: viewOnce,
    );
    if (_socket?.connected == true) {
      _socket!.emit('send_message', entry.toPayload());
    } else {
      _outboxQueue.add(entry);
    }
  }

  void sendTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  void stopTyping(String conversationId) {
    _socket?.emit('typing_stop', {'conversationId': conversationId});
  }

  bool get isConnected => _socket?.connected ?? false;

  /// Returns how many messages are currently waiting in the outbox.
  int get outboxLength => _outboxQueue.length;

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _presenceController.close();
    _eventsController.close();
  }
}
