// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_intent_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentIntentEntity _$PaymentIntentEntityFromJson(Map<String, dynamic> json) =>
    _PaymentIntentEntity(
      orderId: json['orderId'] as String,
      paymentIntentClientSecret: json['paymentIntentClientSecret'] as String,
    );

Map<String, dynamic> _$PaymentIntentEntityToJson(
  _PaymentIntentEntity instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'paymentIntentClientSecret': instance.paymentIntentClientSecret,
};
