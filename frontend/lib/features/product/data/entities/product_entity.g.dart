// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductEntity _$ProductEntityFromJson(Map<String, dynamic> json) =>
    ProductEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toInt(),
      condition: json['condition'] as String,
      status: json['status'] as String,
      sellerId: json['sellerId'] as String,
      postId: json['postId'] as String?,
      sellerName: json['sellerName'] as String?,
      sellerAvatar: json['sellerAvatar'] as String?,
    );

Map<String, dynamic> _$ProductEntityToJson(ProductEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'condition': instance.condition,
      'status': instance.status,
      'sellerId': instance.sellerId,
      'postId': instance.postId,
      'sellerName': instance.sellerName,
      'sellerAvatar': instance.sellerAvatar,
    };
