// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewListResponse _$ReviewListResponseFromJson(Map<String, dynamic> json) =>
    _ReviewListResponse(
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => ReviewEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewListResponseToJson(_ReviewListResponse instance) =>
    <String, dynamic>{
      'reviews': instance.reviews,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };
