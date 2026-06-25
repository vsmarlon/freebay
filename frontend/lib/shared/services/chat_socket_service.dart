import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';

class ChatSocketService {
  io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  String get _wsUrl {
    final apiUrl = AppConfig.apiBaseUrl;
    return apiUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }

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
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> reconnectWithFreshToken() async {
    disconnect();
    await connect();
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', {'conversationId': conversationId});
  }

  void sendMessage(String conversationId, String content) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  void sendTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  bool get isConnected => _socket?.connected ?? false;

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
