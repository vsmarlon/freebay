class UserModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final String? state;
  final bool isVerified;
  final int reputationScore;
  final int totalReviews;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.state,
    required this.isVerified,
    required this.reputationScore,
    required this.totalReviews,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      reputationScore: json['reputationScore'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
