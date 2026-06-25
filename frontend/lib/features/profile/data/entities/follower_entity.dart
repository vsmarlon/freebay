import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'follower_entity.g.dart';

@JsonSerializable()
class FollowerEntity extends Equatable {
  final String id;
  @JsonKey(defaultValue: 'Usuário')
  final String displayName;
  final String? avatarUrl;
  @JsonKey(defaultValue: false)
  final bool isVerified;
  final String? bio;
  @JsonKey(defaultValue: false)
  final bool isFollowing;

  const FollowerEntity({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
    this.bio,
    required this.isFollowing,
  });

  factory FollowerEntity.fromJson(Map<String, dynamic> json) =>
      _$FollowerEntityFromJson(json);

  Map<String, dynamic> toJson() => _$FollowerEntityToJson(this);

  @override
  List<Object?> get props =>
      [id, displayName, avatarUrl, isVerified, bio, isFollowing];
}
