// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageEntity _$MessageEntityFromJson(Map<String, dynamic> json) =>
    _MessageEntity(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String?,
      type: json['type'] as String? ?? 'TEXT',
      attachmentUrl: json['attachmentUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] == null
          ? null
          : MessageEntity.fromJson(json['replyTo'] as Map<String, dynamic>),
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MessageReactionEntity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      viewOnce: json['viewOnce'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MessageEntityToJson(_MessageEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'content': instance.content,
      'type': instance.type,
      'attachmentUrl': instance.attachmentUrl,
      'metadata': instance.metadata,
      'replyToId': instance.replyToId,
      'replyTo': instance.replyTo?.toJson(),
      'reactions': instance.reactions.map((e) => e.toJson()).toList(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'viewOnce': instance.viewOnce,
      'createdAt': instance.createdAt.toIso8601String(),
    };
