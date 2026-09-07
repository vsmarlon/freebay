import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_entity.freezed.dart';
part 'story_entity.g.dart';

@freezed
abstract class StoryUserEntity with _$StoryUserEntity {
  const factory StoryUserEntity({
    required String id,
    required String displayName,
    String? avatarUrl,
    @Default(false) bool isVerified,
  }) = _StoryUserEntity;

  factory StoryUserEntity.fromJson(Map<String, dynamic> json) =>
      _$StoryUserEntityFromJson(json);
}

@freezed
abstract class StoryEntity with _$StoryEntity {
  const StoryEntity._();

  const factory StoryEntity({
    required String id,
    required String userId,
    required String imageUrl,
    required DateTime expiresAt,
    required DateTime createdAt,
    required StoryUserEntity user,
    @Default(false) bool isViewed,
  }) = _StoryEntity;

  factory StoryEntity.fromJson(Map<String, dynamic> json) =>
      _$StoryEntityFromJson(json);

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}

class StoriesResponse {
  final List<StoryEntity> stories;
  final bool userHasStory;

  const StoriesResponse({this.stories = const [], this.userHasStory = false});
}
