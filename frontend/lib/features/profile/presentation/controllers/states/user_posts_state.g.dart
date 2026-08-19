// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_posts_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPostsState _$UserPostsStateFromJson(Map<String, dynamic> json) =>
    _UserPostsState(
      posts:
          (json['posts'] as List<dynamic>?)
              ?.map((e) => PostEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isLoading: json['isLoading'] as bool? ?? false,
      cursor: json['cursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? true,
    );

Map<String, dynamic> _$UserPostsStateToJson(_UserPostsState instance) =>
    <String, dynamic>{
      'posts': instance.posts.map((e) => e.toJson()).toList(),
      'isLoading': instance.isLoading,
      'cursor': instance.cursor,
      'hasMore': instance.hasMore,
    };
