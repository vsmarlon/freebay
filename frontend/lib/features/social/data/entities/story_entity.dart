import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'story_entity.g.dart';

@JsonSerializable()
class StoryUserEntity extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;

  const StoryUserEntity({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory StoryUserEntity.fromJson(Map<String, dynamic> json) =>
      _$StoryUserEntityFromJson(json);
  Map<String, dynamic> toJson() => _$StoryUserEntityToJson(this);

  @override
  List<Object?> get props => [id, displayName, avatarUrl, isVerified];
}

@JsonSerializable()
class StoryEntity extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime expiresAt;
  final DateTime createdAt;
  final StoryUserEntity user;
  final bool isViewed;

  const StoryEntity({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.expiresAt,
    required this.createdAt,
    required this.user,
    this.isViewed = false,
  });

  factory StoryEntity.fromJson(Map<String, dynamic> json) =>
      _$StoryEntityFromJson(json);
  Map<String, dynamic> toJson() => _$StoryEntityToJson(this);

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  @override
  List<Object?> get props =>
      [id, userId, imageUrl, expiresAt, createdAt, user, isViewed];
}
