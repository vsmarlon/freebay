import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_entity.g.dart';

@JsonSerializable()
class UserEntity extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final String? state;
  final bool isVerified;
  final bool isGuest;
  final num reputationScore;
  final int totalReviews;

  const UserEntity({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.bio,
    this.city,
    this.state,
    this.isVerified = false,
    this.isGuest = false,
    this.reputationScore = 0,
    this.totalReviews = 0,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UserEntityToJson(this);

  @override
  List<Object?> get props => [
        id,
        displayName,
        email,
        avatarUrl,
        bio,
        city,
        state,
        isVerified,
        isGuest,
        reputationScore,
        totalReviews,
      ];
}
