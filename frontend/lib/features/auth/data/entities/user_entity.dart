import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_entity.g.dart';

@JsonSerializable()
class UserEntity extends Equatable {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final String? state;
  final bool isVerified;
  final bool isGuest;
  final bool hasCpf;
  final num reputationScore;
  final int totalReviews;
  final int salesCount;
  final int purchasesCount;
  final int followersCount;
  final int followingCount;

  const UserEntity({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.bio,
    this.city,
    this.state,
    this.isVerified = false,
    this.isGuest = false,
    this.hasCpf = false,
    this.reputationScore = 0,
    this.totalReviews = 0,
    this.salesCount = 0,
    this.purchasesCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  String get displayNameOrDefault =>
      displayName ?? (isGuest ? 'Convidado' : 'Usuário');

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
        hasCpf,
        reputationScore,
        totalReviews,
        salesCount,
        purchasesCount,
        followersCount,
        followingCount,
      ];
}
