// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostEntity _$PostEntityFromJson(Map<String, dynamic> json) => PostEntity(
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: UserEntity.fromJson(json['user'] as Map<String, dynamic>),
      product: json['product'] == null
          ? null
          : ProductInfo.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostEntityToJson(PostEntity instance) =>
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
      'createdAt': instance.createdAt.toIso8601String(),
      'user': instance.user,
      'product': instance.product,
    };

ProductInfo _$ProductInfoFromJson(Map<String, dynamic> json) => ProductInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toInt(),
      condition: json['condition'] as String,
    );

Map<String, dynamic> _$ProductInfoToJson(ProductInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'condition': instance.condition,
    };

UserEntity _$UserEntityFromJson(Map<String, dynamic> json) => UserEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserEntityToJson(UserEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'reputationScore': instance.reputationScore,
      'totalReviews': instance.totalReviews,
    };
