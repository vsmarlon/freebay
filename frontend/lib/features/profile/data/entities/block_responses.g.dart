// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockListResponse _$BlockListResponseFromJson(Map<String, dynamic> json) =>
    BlockListResponse(
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BlockListResponseToJson(BlockListResponse instance) =>
    <String, dynamic>{
      'users': instance.users.map((e) => e.toJson()).toList(),
      'limit': instance.limit,
      'offset': instance.offset,
    };

UnblockResponse _$UnblockResponseFromJson(Map<String, dynamic> json) =>
    UnblockResponse(blocked: json['blocked'] as bool? ?? false);

Map<String, dynamic> _$UnblockResponseToJson(UnblockResponse instance) =>
    <String, dynamic>{'blocked': instance.blocked};

BlockResponse _$BlockResponseFromJson(Map<String, dynamic> json) =>
    BlockResponse(blocked: json['blocked'] as bool? ?? false);

Map<String, dynamic> _$BlockResponseToJson(BlockResponse instance) =>
    <String, dynamic>{'blocked': instance.blocked};
