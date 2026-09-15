import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_entity.freezed.dart';
part 'story_entity.g.dart';

enum StoryTextStyle {
  @JsonValue('classic')
  classic,
  @JsonValue('strong')
  strong,
  @JsonValue('editorial')
  editorial,
  @JsonValue('compact')
  compact,
}

@freezed
abstract class StoryTextBlockEntity with _$StoryTextBlockEntity {
  const factory StoryTextBlockEntity({
    required String id,
    required String text,
    required double x,
    required double y,
    required double scale,
    required double rotation,
    required int color,
    required StoryTextStyle style,
    required int zIndex,
  }) = _StoryTextBlockEntity;

  factory StoryTextBlockEntity.fromJson(Map<String, dynamic> json) =>
      _$StoryTextBlockEntityFromJson(json);
}

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
    @Default('IMAGE') String mediaType,
    String? caption,
    List<StoryTextBlockEntity>? textBlocks,
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
  final List<StoryGroupEntity> groups;
  final bool userHasStory;

  const StoriesResponse({this.groups = const [], this.userHasStory = false});

  List<StoryEntity> get stories => [
    for (final group in groups)
      for (final story in group.stories)
        StoryEntity(
          id: story.id,
          userId: group.user.id,
          imageUrl: story.imageUrl,
          mediaType: story.mediaType,
          caption: story.caption,
          textBlocks: story.textBlocks,
          expiresAt: story.expiresAt,
          createdAt: story.createdAt,
          user: group.user,
        ),
  ];
}

class StoryGroupEntity {
  final StoryUserEntity user;
  final List<StoryGroupItem> stories;

  const StoryGroupEntity({required this.user, required this.stories});
}

class StoryGroupItem {
  final String id;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String mediaType;
  final String? caption;
  final List<StoryTextBlockEntity>? textBlocks;
  const StoryGroupItem({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.mediaType = 'IMAGE',
    this.caption,
    this.textBlocks,
  });
}
