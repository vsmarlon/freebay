class UserSearchEntity {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final double reputationScore;
  final int totalReviews;
  final int followersCount;
  final int followingCount;

  const UserSearchEntity({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.isVerified,
    required this.reputationScore,
    required this.totalReviews,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserSearchEntity.fromJson(Map<String, dynamic> json) {
    return UserSearchEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
    );
  }
}
