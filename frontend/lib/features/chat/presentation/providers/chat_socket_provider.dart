import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/shared/services/chat_socket_service.dart';

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});
