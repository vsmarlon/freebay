// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crypto_payment_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CryptoPaymentEntity _$CryptoPaymentEntityFromJson(Map<String, dynamic> json) =>
    _CryptoPaymentEntity(
      orderId: json['orderId'] as String,
      currency: json['currency'] as String? ?? 'XMR',
      address: json['address'] as String,
      paymentId: json['paymentId'] as String?,
      uriQrCode: json['uriQrCode'] as String,
      amountAtomic: json['amountAtomic'] as String,
      amountHuman: json['amountHuman'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$CryptoPaymentEntityToJson(
  _CryptoPaymentEntity instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'currency': instance.currency,
  'address': instance.address,
  'paymentId': instance.paymentId,
  'uriQrCode': instance.uriQrCode,
  'amountAtomic': instance.amountAtomic,
  'amountHuman': instance.amountHuman,
  'expiresAt': instance.expiresAt.toIso8601String(),
};
