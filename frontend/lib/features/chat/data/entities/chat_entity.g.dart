// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatProductInfo _$ChatProductInfoFromJson(Map<String, dynamic> json) =>
    _ChatProductInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String? ?? '',
    );

Map<String, dynamic> _$ChatProductInfoToJson(_ChatProductInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imageUrl': instance.imageUrl,
      'status': instance.status,
    };

_ChatEntity _$ChatEntityFromJson(Map<String, dynamic> json) => _ChatEntity(
  id: json['id'] as String,
  threadType: $enumDecode(_$ChatThreadTypeEnumMap, json['threadType']),
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
  product: json['product'] == null
      ? null
      : ChatProductInfo.fromJson(json['product'] as Map<String, dynamic>),
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ChatEntityToJson(_ChatEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'threadType': _$ChatThreadTypeEnumMap[instance.threadType]!,
      'otherUser': instance.otherUser.toJson(),
      'lastMessage': instance.lastMessageInfo?.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'preference': instance.preference?.toJson(),
      'orderInfo': instance.orderInfo?.toJson(),
      'product': instance.product?.toJson(),
      'unreadCount': instance.unreadCount,
    };

const _$ChatThreadTypeEnumMap = {
  ChatThreadType.order: 'ORDER',
  ChatThreadType.direct: 'DIRECT',
};
