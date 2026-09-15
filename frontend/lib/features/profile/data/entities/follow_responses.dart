import 'package:json_annotation/json_annotation.dart';

part 'follow_responses.g.dart';

@JsonSerializable()
class FollowResponse {
  @JsonKey(defaultValue: false)
  final bool following;
  @JsonKey(defaultValue: 0)
  final int followersCount;
  @JsonKey(defaultValue: 0)
  final int followingCount;

  const FollowResponse({
    required this.following,
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FollowResponseToJson(this);
}

@JsonSerializable()
class FollowStatusResponse {
  @JsonKey(defaultValue: false)
  final bool isFollowing;
  @JsonKey(defaultValue: 0)
  final int followersCount;
  @JsonKey(defaultValue: 0)
  final int followingCount;

  const FollowStatusResponse({
    required this.isFollowing,
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FollowStatusResponseToJson(this);

  FollowStatusResponse copyWith({
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
  }) {
    return FollowStatusResponse(
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}

@JsonSerializable()
class UserBrief {
  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  @JsonKey(defaultValue: false)
  final bool isVerified;
  @JsonKey(defaultValue: 0.0)
  final double reputationScore;

  const UserBrief({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
    required this.isVerified,
    required this.reputationScore,
  });

  factory UserBrief.fromJson(Map<String, dynamic> json) =>
      _$UserBriefFromJson(json);

  Map<String, dynamic> toJson() => _$UserBriefToJson(this);
}

typedef FollowListUser = UserBrief;

@JsonSerializable()
class FollowListResponse {
  final List<FollowListUser> users;
  @JsonKey(defaultValue: 0)
  final int total;
  @JsonKey(defaultValue: 0)
  final int limit;
  @JsonKey(defaultValue: 0)
  final int offset;

  const FollowListResponse({
    this.users = const [],
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory FollowListResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FollowListResponseToJson(this);
}
