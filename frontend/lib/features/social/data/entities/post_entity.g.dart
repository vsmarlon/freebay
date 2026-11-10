// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostMediaEntity _$PostMediaEntityFromJson(Map<String, dynamic> json) =>
    _PostMediaEntity(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      type:
          $enumDecodeNullable(_$PostMediaTypeEnumMap, json['type']) ??
          PostMediaType.image,
      altText: json['altText'] as String?,
      blurHash: json['blurHash'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PostMediaEntityToJson(_PostMediaEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'thumbnailUrl': instance.thumbnailUrl,
      'type': _$PostMediaTypeEnumMap[instance.type]!,
      'altText': instance.altText,
      'blurHash': instance.blurHash,
      'order': instance.order,
    };

const _$PostMediaTypeEnumMap = {
  PostMediaType.image: 'IMAGE',
  PostMediaType.video: 'VIDEO',
};

_PostProductInfo _$PostProductInfoFromJson(Map<String, dynamic> json) =>
    _PostProductInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num?)?.toInt() ?? 0,
      condition: json['condition'] == null
          ? ProductCondition.isNew
          : _productConditionFromJson(json['condition']),
    );

Map<String, dynamic> _$PostProductInfoToJson(_PostProductInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'condition': _productConditionToJson(instance.condition),
    };

_PostEntity _$PostEntityFromJson(Map<String, dynamic> json) => _PostEntity(
  id: json['id'] as String,
  userId: json['userId'] as String,
  content: json['content'] as String?,
  media:
      (json['media'] as List<dynamic>?)
          ?.map((e) => PostMediaEntity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PostMediaEntity>[],
  type:
      $enumDecodeNullable(_$PostTypeEnumMap, json['type']) ?? PostType.regular,
  audience:
      $enumDecodeNullable(_$PostAudienceEnumMap, json['audience']) ??
      PostAudience.everyone,
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
  isQuote: json['isQuote'] as bool? ?? false,
  quoteSource: json['quoteSource'] == null
      ? null
      : QuoteSource.fromJson(json['quoteSource'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostEntityToJson(_PostEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'content': instance.content,
      'media': instance.media.map((e) => e.toJson()).toList(),
      'type': _$PostTypeEnumMap[instance.type]!,
      'audience': _$PostAudienceEnumMap[instance.audience]!,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'sharesCount': instance.sharesCount,
      'isLiked': instance.isLiked,
      'isSaved': instance.isSaved,
      'hasReposted': instance.hasReposted,
      'repostedAt': instance.repostedAt?.toIso8601String(),
      'repostedBy': instance.repostedBy?.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'user': instance.user.toJson(),
      'product': instance.product?.toJson(),
      'isQuote': instance.isQuote,
      'quoteSource': instance.quoteSource?.toJson(),
    };

const _$PostTypeEnumMap = {
  PostType.product: 'PRODUCT',
  PostType.regular: 'REGULAR',
};

const _$PostAudienceEnumMap = {
  PostAudience.everyone: 'EVERYONE',
  PostAudience.closeFriends: 'CLOSE_FRIENDS',
};

QuotePostSource _$QuotePostSourceFromJson(Map<String, dynamic> json) =>
    QuotePostSource(
      id: json['id'] as String,
      post: PostEntity.fromJson(json['post'] as Map<String, dynamic>),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$QuotePostSourceToJson(QuotePostSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'post': instance.post.toJson(),
      'kind': instance.$type,
    };

QuoteCommentSource _$QuoteCommentSourceFromJson(Map<String, dynamic> json) =>
    QuoteCommentSource(
      id: json['id'] as String,
      postId: json['postId'] as String,
      comment: CommentEntity.fromJson(json['comment'] as Map<String, dynamic>),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$QuoteCommentSourceToJson(QuoteCommentSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'comment': instance.comment.toJson(),
      'kind': instance.$type,
    };
