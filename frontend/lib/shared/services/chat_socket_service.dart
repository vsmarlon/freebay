import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';

/// A pending message that was queued while the socket was offline.
class _OutboxEntry {
  final String conversationId;
  final String content;

  const _OutboxEntry({required this.conversationId, required this.content});
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

  Timer? _reconnectTimer;

  /// Internal memory queue for messages sent while offline.
  final List<_OutboxEntry> _outboxQueue = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

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
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
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
      _socket!.emit('send_message', {
        'conversationId': entry.conversationId,
        'content': entry.content,
      });
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
  void sendMessage(String conversationId, String content) {
    if (_socket?.connected == true) {
      _socket!.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
      });
    } else {
      _outboxQueue.add(
        _OutboxEntry(conversationId: conversationId, content: content),
      );
    }
  }

  void sendTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  bool get isConnected => _socket?.connected ?? false;

  /// Returns how many messages are currently waiting in the outbox.
  int get outboxLength => _outboxQueue.length;

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
