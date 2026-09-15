// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowResponse _$FollowResponseFromJson(Map<String, dynamic> json) =>
    FollowResponse(
      following: json['following'] as bool? ?? false,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FollowResponseToJson(FollowResponse instance) =>
    <String, dynamic>{
      'following': instance.following,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
    };

FollowStatusResponse _$FollowStatusResponseFromJson(
  Map<String, dynamic> json,
) => FollowStatusResponse(
  isFollowing: json['isFollowing'] as bool? ?? false,
  followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
  followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FollowStatusResponseToJson(
  FollowStatusResponse instance,
) => <String, dynamic>{
  'isFollowing': instance.isFollowing,
  'followersCount': instance.followersCount,
  'followingCount': instance.followingCount,
};

UserBrief _$UserBriefFromJson(Map<String, dynamic> json) => UserBrief(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  username: json['username'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$UserBriefToJson(UserBrief instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'username': instance.username,
  'avatarUrl': instance.avatarUrl,
  'isVerified': instance.isVerified,
  'reputationScore': instance.reputationScore,
};

FollowListResponse _$FollowListResponseFromJson(Map<String, dynamic> json) =>
    FollowListResponse(
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FollowListResponseToJson(FollowListResponse instance) =>
    <String, dynamic>{
      'users': instance.users.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };
