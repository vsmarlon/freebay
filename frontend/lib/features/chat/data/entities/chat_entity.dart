import 'package:equatable/equatable.dart';

class ChatEntity extends Equatable {
  final String id;
  final String oderId;
  final String oderName;
  final String? oderAvatarUrl;
  final String lastMessage;
  final DateTime timestamp;
  final bool unread;
  final ChatStatus status;

  const ChatEntity({
    required this.id,
    required this.oderId,
    required this.oderName,
    this.oderAvatarUrl,
    required this.lastMessage,
    required this.timestamp,
    this.unread = false,
    this.status = ChatStatus.active,
  });

  factory ChatEntity.fromJson(Map<String, dynamic> json) {
    return ChatEntity(
      id: json['id'] as String,
      oderId: json['oderId'] as String? ?? json['orderId'] as String? ?? '',
      oderName: json['oderName'] as String? ??
          json['orderName'] as String? ??
          'Usuário',
      oderAvatarUrl: json['oderAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      unread: json['unread'] as bool? ?? false,
      status: ChatStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatStatus.active,
      ),
    );
  }

  @override
  List<Object?> get props =>
      [id, oderId, oderName, lastMessage, timestamp, unread, status];
}

enum ChatStatus { active, archived, order, direct }
