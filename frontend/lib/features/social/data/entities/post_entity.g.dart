// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostProductInfo _$PostProductInfoFromJson(Map<String, dynamic> json) =>
    _PostProductInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toInt(),
      condition: json['condition'] as String,
    );

Map<String, dynamic> _$PostProductInfoToJson(_PostProductInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'condition': instance.condition,
    };

_PostEntity _$PostEntityFromJson(Map<String, dynamic> json) => _PostEntity(
  id: json['id'] as String,
  userId: json['userId'] as String,
  content: json['content'] as String?,
  imageUrl: json['imageUrl'] as String?,
  type: json['type'] as String? ?? 'REGULAR',
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
  sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
  isLiked: json['isLiked'] as bool? ?? false,
  isSaved: json['isSaved'] as bool? ?? false,
  hasReposted: json['hasReposted'] as bool? ?? false,
  repostedAt: json['repostedAt'] == null
      ? null
      : DateTime.parse(json['repostedAt'] as String),
  repostedBy: json['repostedBy'] == null
      ? null
      : UserEntity.fromJson(json['repostedBy'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  user: UserEntity.fromJson(json['user'] as Map<String, dynamic>),
  product: json['product'] == null
      ? null
      : PostProductInfo.fromJson(json['product'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostEntityToJson(_PostEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'content': instance.content,
      'imageUrl': instance.imageUrl,
      'type': instance.type,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'sharesCount': instance.sharesCount,
      'isLiked': instance.isLiked,
      'isSaved': instance.isSaved,
      'hasReposted': instance.hasReposted,
      'repostedAt': instance.repostedAt?.toIso8601String(),
      'repostedBy': instance.repostedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'user': instance.user,
      'product': instance.product,
    };
