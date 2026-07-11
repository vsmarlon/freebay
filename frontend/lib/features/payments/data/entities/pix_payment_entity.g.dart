// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pix_payment_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PixPaymentEntity _$PixPaymentEntityFromJson(Map<String, dynamic> json) =>
    _PixPaymentEntity(
      orderId: json['orderId'] as String,
      pixQrCode: json['pixQrCode'] as String? ?? '',
      pixImage: json['pixImage'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$PixPaymentEntityToJson(_PixPaymentEntity instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'pixQrCode': instance.pixQrCode,
      'pixImage': instance.pixImage,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
