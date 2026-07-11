// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartEntity _$CartEntityFromJson(Map<String, dynamic> json) => _CartEntity(
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItemEntity.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalItems: (json['totalItems'] as num).toInt(),
  totalPrice: (json['totalPrice'] as num).toInt(),
);

Map<String, dynamic> _$CartEntityToJson(_CartEntity instance) =>
    <String, dynamic>{
      'items': instance.items,
      'totalItems': instance.totalItems,
      'totalPrice': instance.totalPrice,
    };
