// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationPreference _$ConversationPreferenceFromJson(
  Map<String, dynamic> json,
) => _ConversationPreference(
  id: json['id'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  orderId: json['orderId'] as String?,
  directConversationId: json['directConversationId'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  theme: json['theme'] as String? ?? 'DEFAULT',
  backgroundUrl: json['backgroundUrl'] as String?,
);

Map<String, dynamic> _$ConversationPreferenceToJson(
  _ConversationPreference instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'orderId': instance.orderId,
  'directConversationId': instance.directConversationId,
  'isArchived': instance.isArchived,
  'isDeleted': instance.isDeleted,
  'theme': instance.theme,
  'backgroundUrl': instance.backgroundUrl,
};
