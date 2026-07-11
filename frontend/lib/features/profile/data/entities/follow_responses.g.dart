// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FollowResponse _$FollowResponseFromJson(Map<String, dynamic> json) =>
    _FollowResponse(
      following: json['following'] as bool,
      followersCount: (json['followersCount'] as num).toInt(),
      followingCount: (json['followingCount'] as num).toInt(),
    );

Map<String, dynamic> _$FollowResponseToJson(_FollowResponse instance) =>
    <String, dynamic>{
      'following': instance.following,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
    };

_FollowStatusResponse _$FollowStatusResponseFromJson(
  Map<String, dynamic> json,
) => _FollowStatusResponse(
  isFollowing: json['isFollowing'] as bool,
  followersCount: (json['followersCount'] as num).toInt(),
  followingCount: (json['followingCount'] as num).toInt(),
);

Map<String, dynamic> _$FollowStatusResponseToJson(
  _FollowStatusResponse instance,
) => <String, dynamic>{
  'isFollowing': instance.isFollowing,
  'followersCount': instance.followersCount,
  'followingCount': instance.followingCount,
};

_FollowListUser _$FollowListUserFromJson(Map<String, dynamic> json) =>
    _FollowListUser(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool,
      reputationScore: (json['reputationScore'] as num).toDouble(),
    );

Map<String, dynamic> _$FollowListUserToJson(_FollowListUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'reputationScore': instance.reputationScore,
    };

_FollowListResponse _$FollowListResponseFromJson(Map<String, dynamic> json) =>
    _FollowListResponse(
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => FollowListUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$FollowListResponseToJson(_FollowListResponse instance) =>
    <String, dynamic>{
      'users': instance.users,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };
