// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_search_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSearchEntity _$UserSearchEntityFromJson(Map<String, dynamic> json) =>
    _UserSearchEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserSearchEntityToJson(_UserSearchEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'bio': instance.bio,
      'isVerified': instance.isVerified,
      'reputationScore': instance.reputationScore,
      'totalReviews': instance.totalReviews,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
    };
