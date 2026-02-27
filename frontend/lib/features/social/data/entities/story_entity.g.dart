// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryUserEntity _$StoryUserEntityFromJson(Map<String, dynamic> json) =>
    StoryUserEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$StoryUserEntityToJson(StoryUserEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
    };

StoryEntity _$StoryEntityFromJson(Map<String, dynamic> json) => StoryEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      imageUrl: json['imageUrl'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: StoryUserEntity.fromJson(json['user'] as Map<String, dynamic>),
      isViewed: json['isViewed'] as bool? ?? false,
    );

Map<String, dynamic> _$StoryEntityToJson(StoryEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'imageUrl': instance.imageUrl,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'user': instance.user,
      'isViewed': instance.isViewed,
    };
