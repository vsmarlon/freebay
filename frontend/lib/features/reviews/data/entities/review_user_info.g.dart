// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewUserInfo _$ReviewUserInfoFromJson(Map<String, dynamic> json) =>
    _ReviewUserInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      avatarBlurHash: json['avatarBlurHash'] as String?,
    );

Map<String, dynamic> _$ReviewUserInfoToJson(_ReviewUserInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'avatarBlurHash': instance.avatarBlurHash,
    };
