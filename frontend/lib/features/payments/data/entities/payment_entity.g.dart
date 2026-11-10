// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentEntity _$PaymentEntityFromJson(Map<String, dynamic> json) =>
    _PaymentEntity(
      orderId: json['orderId'] as String,
      stripeSessionId: json['stripeSessionId'] as String,
      checkoutUrl: json['checkoutUrl'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$PaymentEntityToJson(_PaymentEntity instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'stripeSessionId': instance.stripeSessionId,
      'checkoutUrl': instance.checkoutUrl,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
