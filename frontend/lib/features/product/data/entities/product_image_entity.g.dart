// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_image_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductImageEntity _$ProductImageEntityFromJson(Map<String, dynamic> json) =>
    _ProductImageEntity(
      id: json['id'] as String,
      url: json['url'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      productId: json['productId'] as String,
    );

Map<String, dynamic> _$ProductImageEntityToJson(_ProductImageEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'order': instance.order,
      'productId': instance.productId,
    };
