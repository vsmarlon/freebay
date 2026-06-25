// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItemEntity _$CartItemEntityFromJson(Map<String, dynamic> json) =>
    CartItemEntity(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toInt(),
      product: ProductEntity.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CartItemEntityToJson(CartItemEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'quantity': instance.quantity,
      'subtotal': instance.subtotal,
      'product': instance.product,
    };
