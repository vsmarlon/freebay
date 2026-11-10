// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transaction_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletTransactionEntity _$WalletTransactionEntityFromJson(
  Map<String, dynamic> json,
) => WalletTransactionEntity(
  id: json['id'] as String,
  amount: (json['amount'] as num).toInt(),
  kind: $enumDecode(
    _$WalletBalanceKindEnumMap,
    json['kind'],
    unknownValue: WalletBalanceKind.available,
  ),
  reason: $enumDecode(
    _$WalletEntryReasonEnumMap,
    json['reason'],
    unknownValue: WalletEntryReason.adjustment,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  orderId: json['orderId'] as String?,
  productTitle: json['productTitle'] as String?,
);

Map<String, dynamic> _$WalletTransactionEntityToJson(
  WalletTransactionEntity instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'kind': _$WalletBalanceKindEnumMap[instance.kind]!,
  'reason': _$WalletEntryReasonEnumMap[instance.reason]!,
  'productTitle': instance.productTitle,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$WalletBalanceKindEnumMap = {
  WalletBalanceKind.available: 'AVAILABLE',
  WalletBalanceKind.pending: 'PENDING',
  WalletBalanceKind.totalEarned: 'TOTAL_EARNED',
};

const _$WalletEntryReasonEnumMap = {
  WalletEntryReason.saleHeld: 'SALE_HELD',
  WalletEntryReason.saleReleased: 'SALE_RELEASED',
  WalletEntryReason.holdReleased: 'HOLD_RELEASED',
  WalletEntryReason.refund: 'REFUND',
  WalletEntryReason.disputeRefund: 'DISPUTE_REFUND',
  WalletEntryReason.disputeRelease: 'DISPUTE_RELEASE',
  WalletEntryReason.payout: 'PAYOUT',
  WalletEntryReason.withdrawal: 'WITHDRAWAL',
  WalletEntryReason.adjustment: 'ADJUSTMENT',
};
