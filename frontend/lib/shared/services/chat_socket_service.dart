import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/events/chat_event.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';

typedef ChatTokenReader = Future<String?> Function();
typedef ChatSocketFactory = ChatSocketClient Function(String url, String token);
typedef ChatConnectivityStream = Stream<List<ConnectivityResult>> Function();

abstract interface class ChatSocketClient {
  bool get connected;
  void connect();
  void dispose();
  void emit(String event, [dynamic data]);
  void onConnect(void Function(dynamic) callback);
  void onConnectError(void Function(dynamic) callback);
  void onDisconnect(void Function(dynamic) callback);
  void on(String event, void Function(dynamic) callback);
}

class _IoChatSocketClient implements ChatSocketClient {
  _IoChatSocketClient(this._socket);

  final io.Socket _socket;

  @override
  bool get connected => _socket.connected;

  @override
  void connect() => _socket.connect();

  @override
  void dispose() => _socket.dispose();

  @override
  void emit(String event, [dynamic data]) => _socket.emit(event, data);

  @override
  void onConnect(void Function(dynamic) callback) {
    _socket.onConnect(callback);
  }

  @override
  void onConnectError(void Function(dynamic) callback) {
    _socket.onConnectError(callback);
  }

  @override
  void onDisconnect(void Function(dynamic) callback) {
    _socket.onDisconnect(callback);
  }

  @override
  void on(String event, void Function(dynamic) callback) {
    _socket.on(event, callback);
  }
}

/// Manages the Socket.IO connection for real-time chat.
///
class ChatSocketService {
  ChatSocketService({
    ChatTokenReader? tokenReader,
    ChatSocketFactory? socketFactory,
    ChatConnectivityStream? connectivityStream,
  }) : _tokenReader = tokenReader ?? StorageService.getToken,
       _socketFactory =
           socketFactory ??
           ((url, token) => _IoChatSocketClient(
             io.io(url, <String, dynamic>{
               'forceNew': true,
               'auth': {'token': token},
               'transports': ['websocket'],
               'autoConnect': false,
             }),
           )),
       _connectivityStream =
           connectivityStream ?? (() => Connectivity().onConnectivityChanged);

  final ChatTokenReader _tokenReader;
  final ChatSocketFactory _socketFactory;
  final ChatConnectivityStream _connectivityStream;
  ChatSocketClient? _socket;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventsController = StreamController<ChatEvent>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Future<void>? _connectOperation;
  final Set<String> _joinedConversations = {};
  String? _socketToken;
  int _generation = 0;
  bool _desiredConnection = false;
  bool _disposed = false;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<ChatEvent> get events => _eventsController.stream;

  String get _wsUrl {
    final apiUrl = AppConfig.apiBaseUrl;
    return apiUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }

  // ── Connection management ────────────────────────────────────────────────

  Future<void> connect() {
    if (_disposed) return Future.value();
    _desiredConnection = true;
    final pending = _connectOperation;
    if (pending != null) return pending;

    final operation = _connect();
    _connectOperation = operation;
    return operation.whenComplete(() {
      if (identical(_connectOperation, operation)) _connectOperation = null;
    });
  }

  void disconnect() {
    if (_disposed) return;
    _desiredConnection = false;
    _generation++;
    _connectOperation = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _socket?.dispose();
    _socket = null;
    _socketToken = null;
    _joinedConversations.clear();
  }

  Future<void> reconnectWithFreshToken() async {
    disconnect();
    await connect();
  }

  Future<void> _connect() async {
    final generation = _generation;
    final token = await _tokenReader();
    if (!_canContinue(generation) || token == null) {
      if (_canContinue(generation) && token == null) _teardownSocket();
      return;
    }

    if (_socket?.connected == true && _socketToken == token) return;
    if (_socket != null && _socketToken != token) _teardownSocket();
    if (!_canContinue(generation)) return;

    final socket = _socketFactory('$_wsUrl/chat', token);
    _socket = socket;
    _socketToken = token;
    _installListeners(socket, generation);
    _connectivitySub ??= _connectivityStream().listen(_onConnectivityChanged);
    socket.connect();
  }

  bool _canContinue(int generation) =>
      !_disposed && _desiredConnection && generation == _generation;

  void _teardownSocket() {
    final socket = _socket;
    _socket = null;
    _socketToken = null;
    socket?.dispose();
  }

  bool _isCurrent(ChatSocketClient socket, int generation) =>
      _canContinue(generation) && identical(_socket, socket);

  void _installListeners(ChatSocketClient socket, int generation) {
    socket
      ..onConnect((_) {
        if (!_isCurrent(socket, generation)) return;
        for (final conversationId in _joinedConversations) {
          socket.emit('join_conversation', {'conversationId': conversationId});
        }
      })
      ..onConnectError((error) {
        if (!_isCurrent(socket, generation)) return;
        if (error is Map &&
            error['message']?.toString().contains('jwt') == true) {
          disconnect();
        }
      })
      ..onDisconnect((reason) {
        if (!_isCurrent(socket, generation)) return;
        if ((reason is String && reason.contains('jwt')) ||
            reason == 'io server disconnect') {
          disconnect();
        }
      })
      ..on('new_message', (data) {
        if (!_isCurrent(socket, generation) || data is! Map) return;
        final payload = Map<String, dynamic>.from(data);
        _messageController.add(payload);
        try {
          _eventsController.add(
            NewMessageEvent(MessageEntity.fromJson(payload)),
          );
        } catch (e) {
          debugPrint('[chat-socket] dropped malformed new_message: $e');
        }
      })
      ..on('reaction_updated', (data) {
        if (!_isCurrent(socket, generation) || data is! Map) return;
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
      })
      ..on('message_deleted', (data) {
        if (!_isCurrent(socket, generation) || data is! Map<String, dynamic>) {
          return;
        }
        _eventsController.add(
          MessageDeletedEvent(data['messageId'] as String? ?? ''),
        );
      })
      ..on('user_typing', (data) {
        if (!_isCurrent(socket, generation) || data is! Map<String, dynamic>) {
          return;
        }
        final userId = data['userId'] as String?;
        if (userId != null) _eventsController.add(UserTypingEvent(userId));
      })
      ..on('user_stopped_typing', (data) {
        if (!_isCurrent(socket, generation) || data is! Map<String, dynamic>) {
          return;
        }
        final userId = data['userId'] as String?;
        if (userId != null) {
          _eventsController.add(UserStoppedTypingEvent(userId));
        }
      })
      ..on('user_online', (data) {
        if (!_isCurrent(socket, generation) || data is! Map<String, dynamic>) {
          return;
        }
        final userId = data['userId'] as String?;
        if (userId != null) _eventsController.add(UserOnlineEvent(userId));
      })
      ..on('user_offline', (data) {
        if (!_isCurrent(socket, generation) || data is! Map<String, dynamic>) {
          return;
        }
        final userId = data['userId'] as String?;
        if (userId != null) _eventsController.add(UserOfflineEvent(userId));
      });
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (hasNetwork && _desiredConnection && !_disposed && !isConnected) {
      connect();
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────

  void joinConversation(String conversationId) {
    _joinedConversations.add(conversationId);
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _joinedConversations.remove(conversationId);
    _socket?.emit('leave_conversation', {'conversationId': conversationId});
  }

  void sendTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  void stopTyping(String conversationId) {
    _socket?.emit('typing_stop', {'conversationId': conversationId});
  }

  bool get isConnected => _socket?.connected ?? false;

  void dispose() {
    if (_disposed) return;
    disconnect();
    _disposed = true;
    _messageController.close();
    _eventsController.close();
  }
}
