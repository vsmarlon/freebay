// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BlockListUser _$BlockListUserFromJson(Map<String, dynamic> json) =>
    _BlockListUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool,
      reputationScore: (json['reputationScore'] as num).toDouble(),
    );

Map<String, dynamic> _$BlockListUserToJson(_BlockListUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'reputationScore': instance.reputationScore,
    };

_BlockListResponse _$BlockListResponseFromJson(Map<String, dynamic> json) =>
    _BlockListResponse(
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => BlockListUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$BlockListResponseToJson(_BlockListResponse instance) =>
    <String, dynamic>{
      'users': instance.users,
      'limit': instance.limit,
      'offset': instance.offset,
    };

_UnblockResponse _$UnblockResponseFromJson(Map<String, dynamic> json) =>
    _UnblockResponse(blocked: json['blocked'] as bool);

Map<String, dynamic> _$UnblockResponseToJson(_UnblockResponse instance) =>
    <String, dynamic>{'blocked': instance.blocked};

_BlockResponse _$BlockResponseFromJson(Map<String, dynamic> json) =>
    _BlockResponse(blocked: json['blocked'] as bool);

Map<String, dynamic> _$BlockResponseToJson(_BlockResponse instance) =>
    <String, dynamic>{'blocked': instance.blocked};
