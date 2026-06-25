// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewEntity _$ReviewEntityFromJson(Map<String, dynamic> json) => ReviewEntity(
      id: json['id'] as String,
      reviewerId: json['reviewerId'] as String,
      reviewedId: json['reviewedId'] as String,
      orderId: json['orderId'] as String,
      type: _reviewTypeFromJson(json['type'] as String),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewer: json['reviewer'] == null
          ? null
          : ReviewUserInfo.fromJson(json['reviewer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReviewEntityToJson(ReviewEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reviewerId': instance.reviewerId,
      'reviewedId': instance.reviewedId,
      'orderId': instance.orderId,
      'type': _reviewTypeToJson(instance.type),
      'score': instance.score,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
      'reviewer': instance.reviewer,
    };

ReviewUserInfo _$ReviewUserInfoFromJson(Map<String, dynamic> json) =>
    ReviewUserInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$ReviewUserInfoToJson(ReviewUserInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

ReviewListResponse _$ReviewListResponseFromJson(Map<String, dynamic> json) =>
    ReviewListResponse(
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => ReviewEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewListResponseToJson(ReviewListResponse instance) =>
    <String, dynamic>{
      'reviews': instance.reviews,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };
