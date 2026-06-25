// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatEntity _$ChatEntityFromJson(Map<String, dynamic> json) => ChatEntity(
      id: json['id'] as String,
      threadType: _threadTypeFromJson(json['threadType'] as String?),
      otherUserId: json['otherUserId'] as String,
      otherName: json['otherName'] as String,
      otherAvatarUrl: json['otherAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      unread: json['unread'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      orderStatus: json['orderStatus'] as String?,
      preference: json['preference'] == null
          ? null
          : ConversationPreference.fromJson(
              json['preference'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatEntityToJson(ChatEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'threadType': _threadTypeToJson(instance.threadType),
      'otherUserId': instance.otherUserId,
      'otherName': instance.otherName,
      'otherAvatarUrl': instance.otherAvatarUrl,
      'lastMessage': instance.lastMessage,
      'timestamp': instance.timestamp.toIso8601String(),
      'unread': instance.unread,
      'isArchived': instance.isArchived,
      'orderStatus': instance.orderStatus,
      'preference': instance.preference,
    };
