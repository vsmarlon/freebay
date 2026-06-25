// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follower_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowerEntity _$FollowerEntityFromJson(Map<String, dynamic> json) =>
    FollowerEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Usuário',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      bio: json['bio'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );

Map<String, dynamic> _$FollowerEntityToJson(FollowerEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'bio': instance.bio,
      'isFollowing': instance.isFollowing,
    };
