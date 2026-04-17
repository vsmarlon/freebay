// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentEntity _$CommentEntityFromJson(Map<String, dynamic> json) =>
    CommentEntity(
      id: json['id'] as String,
      content: json['content'] as String,
      userId: json['userId'] as String,
      postId: json['postId'] as String,
      parentId: json['parentId'] as String?,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: json['user'] == null
          ? null
          : UserEntity.fromJson(json['user'] as Map<String, dynamic>),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => CommentEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$CommentEntityToJson(CommentEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'userId': instance.userId,
      'postId': instance.postId,
      'parentId': instance.parentId,
      'likesCount': instance.likesCount,
      'isLiked': instance.isLiked,
      'createdAt': instance.createdAt.toIso8601String(),
      'user': instance.user,
      'replies': instance.replies,
    };
