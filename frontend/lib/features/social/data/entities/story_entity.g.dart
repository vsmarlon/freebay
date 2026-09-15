// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoryTextBlockEntity _$StoryTextBlockEntityFromJson(
  Map<String, dynamic> json,
) => _StoryTextBlockEntity(
  id: json['id'] as String,
  text: json['text'] as String,
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  scale: (json['scale'] as num).toDouble(),
  rotation: (json['rotation'] as num).toDouble(),
  color: (json['color'] as num).toInt(),
  style: $enumDecode(_$StoryTextStyleEnumMap, json['style']),
  zIndex: (json['zIndex'] as num).toInt(),
);

Map<String, dynamic> _$StoryTextBlockEntityToJson(
  _StoryTextBlockEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'x': instance.x,
  'y': instance.y,
  'scale': instance.scale,
  'rotation': instance.rotation,
  'color': instance.color,
  'style': _$StoryTextStyleEnumMap[instance.style]!,
  'zIndex': instance.zIndex,
};

const _$StoryTextStyleEnumMap = {
  StoryTextStyle.classic: 'classic',
  StoryTextStyle.strong: 'strong',
  StoryTextStyle.editorial: 'editorial',
  StoryTextStyle.compact: 'compact',
};

_StoryUserEntity _$StoryUserEntityFromJson(Map<String, dynamic> json) =>
    _StoryUserEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$StoryUserEntityToJson(_StoryUserEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
    };

_StoryEntity _$StoryEntityFromJson(Map<String, dynamic> json) => _StoryEntity(
  id: json['id'] as String,
  userId: json['userId'] as String,
  imageUrl: json['imageUrl'] as String,
  mediaType: json['mediaType'] as String? ?? 'IMAGE',
  caption: json['caption'] as String?,
  textBlocks: (json['textBlocks'] as List<dynamic>?)
      ?.map((e) => StoryTextBlockEntity.fromJson(e as Map<String, dynamic>))
      .toList(),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  user: StoryUserEntity.fromJson(json['user'] as Map<String, dynamic>),
  isViewed: json['isViewed'] as bool? ?? false,
);

Map<String, dynamic> _$StoryEntityToJson(_StoryEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'imageUrl': instance.imageUrl,
      'mediaType': instance.mediaType,
      'caption': instance.caption,
      'textBlocks': instance.textBlocks?.map((e) => e.toJson()).toList(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'user': instance.user.toJson(),
      'isViewed': instance.isViewed,
    };
