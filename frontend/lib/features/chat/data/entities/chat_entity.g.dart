// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatEntity _$ChatEntityFromJson(Map<String, dynamic> json) => _ChatEntity(
  id: json['id'] as String,
  threadType: _threadTypeFromJson(json['threadType'] as String?),
  otherUser: UserEntity.fromJson(json['otherUser'] as Map<String, dynamic>),
  lastMessageInfo: json['lastMessage'] == null
      ? null
      : LastMessageInfo.fromJson(json['lastMessage'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  preference: json['preference'] == null
      ? null
      : ConversationPreference.fromJson(
          json['preference'] as Map<String, dynamic>,
        ),
  orderInfo: json['orderInfo'] == null
      ? null
      : OrderInfo.fromJson(json['orderInfo'] as Map<String, dynamic>),
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ChatEntityToJson(_ChatEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'threadType': _threadTypeToJson(instance.threadType),
      'otherUser': instance.otherUser.toJson(),
      'lastMessage': instance.lastMessageInfo?.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'preference': instance.preference?.toJson(),
      'orderInfo': instance.orderInfo?.toJson(),
      'unreadCount': instance.unreadCount,
    };
