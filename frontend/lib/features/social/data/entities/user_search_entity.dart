import 'package:json_annotation/json_annotation.dart';

part 'user_search_entity.g.dart';

@JsonSerializable()
class UserSearchEntity {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  @JsonKey(defaultValue: false)
  final bool isVerified;
  @JsonKey(defaultValue: 0.0)
  final double reputationScore;
  @JsonKey(defaultValue: 0)
  final int totalReviews;
  @JsonKey(defaultValue: 0)
  final int followersCount;
  @JsonKey(defaultValue: 0)
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

  factory UserSearchEntity.fromJson(Map<String, dynamic> json) =>
      _$UserSearchEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UserSearchEntityToJson(this);
}
