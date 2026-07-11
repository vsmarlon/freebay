// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewEntity _$ReviewEntityFromJson(Map<String, dynamic> json) =>
    _ReviewEntity(
      id: json['id'] as String,
      reviewerId: json['reviewerId'] as String,
      reviewedId: json['reviewedId'] as String,
      orderId: json['orderId'] as String,
      type: _reviewTypeFromJson(json['type'] as String),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewer: json['reviewer'] == null
          ? null
          : ReviewUserInfo.fromJson(json['reviewer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReviewEntityToJson(_ReviewEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reviewerId': instance.reviewerId,
      'reviewedId': instance.reviewedId,
      'orderId': instance.orderId,
      'type': _reviewTypeToJson(instance.type),
      'score': instance.score,
      'comment': instance.comment,
      'images': instance.images,
      'createdAt': instance.createdAt.toIso8601String(),
      'reviewer': instance.reviewer,
    };
