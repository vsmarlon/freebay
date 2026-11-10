// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartEntity _$CartEntityFromJson(Map<String, dynamic> json) => _CartEntity(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CartItemEntity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
  totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CartEntityToJson(_CartEntity instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'totalItems': instance.totalItems,
      'totalPrice': instance.totalPrice,
    };
