// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductEntity _$ProductEntityFromJson(Map<String, dynamic> json) =>
    _ProductEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      condition: json['condition'] as String? ?? 'NEW',
      status: json['status'] as String? ?? 'ACTIVE',
      sellerId: json['sellerId'] as String,
      postId: json['postId'] as String?,
      seller: json['seller'] == null
          ? null
          : UserEntity.fromJson(json['seller'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ProductImageEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProductEntityToJson(_ProductEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'condition': instance.condition,
      'status': instance.status,
      'sellerId': instance.sellerId,
      'postId': instance.postId,
      'seller': instance.seller?.toJson(),
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'quantity': instance.quantity,
      'soldCount': instance.soldCount,
    };
