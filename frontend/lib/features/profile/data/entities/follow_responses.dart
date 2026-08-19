class FollowResponse {
  final bool following;
  final int followersCount;
  final int followingCount;

  const FollowResponse({
    required this.following,
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowResponse.fromJson(Map<String, dynamic> json) => FollowResponse(
    following: json['following'] as bool? ?? false,
    followersCount: json['followersCount'] as int? ?? 0,
    followingCount: json['followingCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'following': following,
    'followersCount': followersCount,
    'followingCount': followingCount,
  };
}

class FollowStatusResponse {
  final bool isFollowing;
  final int followersCount;
  final int followingCount;

  const FollowStatusResponse({
    required this.isFollowing,
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowStatusResponse.fromJson(Map<String, dynamic> json) =>
      FollowStatusResponse(
        isFollowing: json['isFollowing'] as bool? ?? false,
        followersCount: json['followersCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'isFollowing': isFollowing,
    'followersCount': followersCount,
    'followingCount': followingCount,
  };
}

class FollowListUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final double reputationScore;

  const FollowListUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
    required this.reputationScore,
  });

  factory FollowListUser.fromJson(Map<String, dynamic> json) => FollowListUser(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    isVerified: json['isVerified'] as bool? ?? false,
    reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'isVerified': isVerified,
    'reputationScore': reputationScore,
  };
}

class FollowListResponse {
  final List<FollowListUser> users;
  final int total;
  final int limit;
  final int offset;

  const FollowListResponse({
    this.users = const [],
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory FollowListResponse.fromJson(Map<String, dynamic> json) =>
      FollowListResponse(
        users:
            (json['users'] as List<dynamic>?)
                ?.map((e) => FollowListUser.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        total: json['total'] as int? ?? 0,
        limit: json['limit'] as int? ?? 0,
        offset: json['offset'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'users': users.map((e) => e.toJson()).toList(),
    'total': total,
    'limit': limit,
    'offset': offset,
  };
}
