// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_message_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LastMessageInfo _$LastMessageInfoFromJson(Map<String, dynamic> json) =>
    _LastMessageInfo(
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$LastMessageInfoToJson(_LastMessageInfo instance) =>
    <String, dynamic>{
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
    };
