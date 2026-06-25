import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:freebay/features/chat/data/entities/conversation_preference.dart';

part 'chat_entity.g.dart';

ChatThreadType _threadTypeFromJson(String? value) =>
    value == 'ORDER' ? ChatThreadType.order : ChatThreadType.direct;

String _threadTypeToJson(ChatThreadType type) =>
    type == ChatThreadType.order ? 'ORDER' : 'DIRECT';

@JsonSerializable()
class ChatEntity extends Equatable {
  final String id;
  @JsonKey(fromJson: _threadTypeFromJson, toJson: _threadTypeToJson)
  final ChatThreadType threadType;
  final String otherUserId;
  final String otherName;
  final String? otherAvatarUrl;
  final String? lastMessage;
  final DateTime timestamp;
  final bool unread;
  final bool isArchived;
  final String? orderStatus;
  final ConversationPreference? preference;

  const ChatEntity({
    required this.id,
    required this.threadType,
    required this.otherUserId,
    required this.otherName,
    this.otherAvatarUrl,
    this.lastMessage,
    required this.timestamp,
    this.unread = false,
    this.isArchived = false,
    this.orderStatus,
    this.preference,
  });

  factory ChatEntity.fromJson(Map<String, dynamic> json) {
    final timestamp = json['lastMessage']?['createdAt'] as String? ??
        json['createdAt'] as String? ??
        DateTime.now().toIso8601String();

    final normalized = Map<String, dynamic>.from(json)
      ..['otherUserId'] = json['otherUser']?['id'] as String? ?? ''
      ..['otherName'] =
          json['otherUser']?['displayName'] as String? ?? 'Usuário'
      ..['otherAvatarUrl'] = json['otherUser']?['avatarUrl'] as String?
      ..['lastMessage'] = json['lastMessage']?['content'] as String?
      ..['timestamp'] = timestamp
      ..['unread'] = (json['unreadCount'] as int? ?? 0) > 0
      ..['isArchived'] = json['preference']?['isArchived'] as bool? ?? false
      ..['orderStatus'] = json['orderInfo']?['status'] as String?;

    return _$ChatEntityFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$ChatEntityToJson(this);

  ChatEntity copyWith({
    bool? unread,
    bool? isArchived,
    ConversationPreference? preference,
    String? lastMessage,
    DateTime? timestamp,
    String? orderStatus,
  }) {
    return ChatEntity(
      id: id,
      threadType: threadType,
      otherUserId: otherUserId,
      otherName: otherName,
      otherAvatarUrl: otherAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unread: unread ?? this.unread,
      isArchived: isArchived ?? this.isArchived,
      orderStatus: orderStatus ?? this.orderStatus,
      preference: preference ?? this.preference,
    );
  }

  @override
  List<Object?> get props => [
        id,
        threadType,
        otherUserId,
        otherName,
        lastMessage,
        timestamp,
        unread,
        isArchived,
        orderStatus,
        preference,
      ];
}
