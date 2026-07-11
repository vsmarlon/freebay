// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_reaction_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageReactionEntity _$MessageReactionEntityFromJson(
  Map<String, dynamic> json,
) => _MessageReactionEntity(
  emoji: json['emoji'] as String,
  count: (json['count'] as num).toInt(),
  userIds: (json['userIds'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$MessageReactionEntityToJson(
  _MessageReactionEntity instance,
) => <String, dynamic>{
  'emoji': instance.emoji,
  'count': instance.count,
  'userIds': instance.userIds,
};
