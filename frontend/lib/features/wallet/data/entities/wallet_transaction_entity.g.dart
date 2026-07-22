// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transaction_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletTransactionEntity _$WalletTransactionEntityFromJson(
  Map<String, dynamic> json,
) => WalletTransactionEntity(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  amount: (json['amount'] as num).toInt(),
  status: json['status'] as String,
  type: $enumDecode(
    _$WalletTransactionTypeEnumMap,
    json['type'],
    unknownValue: WalletTransactionType.purchase,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  productTitle: json['productTitle'] as String?,
);

Map<String, dynamic> _$WalletTransactionEntityToJson(
  WalletTransactionEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'status': instance.status,
  'type': _$WalletTransactionTypeEnumMap[instance.type]!,
  'productTitle': instance.productTitle,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$WalletTransactionTypeEnumMap = {
  WalletTransactionType.purchase: 'PURCHASE',
  WalletTransactionType.sale: 'SALE',
};
