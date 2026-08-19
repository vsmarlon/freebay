// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_checkout_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartCheckoutItemEntity _$CartCheckoutItemEntityFromJson(
  Map<String, dynamic> json,
) => _CartCheckoutItemEntity(
  orderId: json['orderId'] as String,
  productId: json['productId'] as String,
  productTitle: json['productTitle'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  amount: (json['amount'] as num?)?.toInt() ?? 0,
  checkoutUrl: json['checkoutUrl'] as String? ?? '',
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$CartCheckoutItemEntityToJson(
  _CartCheckoutItemEntity instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'productId': instance.productId,
  'productTitle': instance.productTitle,
  'quantity': instance.quantity,
  'amount': instance.amount,
  'checkoutUrl': instance.checkoutUrl,
  'expiresAt': instance.expiresAt.toIso8601String(),
};

_CartCheckoutEntity _$CartCheckoutEntityFromJson(Map<String, dynamic> json) =>
    _CartCheckoutEntity(
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CartCheckoutItemEntity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CartCheckoutEntityToJson(_CartCheckoutEntity instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'totalOrders': instance.totalOrders,
      'totalAmount': instance.totalAmount,
    };
