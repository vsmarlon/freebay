import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/wallet/domain/wallet_constants.dart';

part 'wallet_transaction_entity.g.dart';

@JsonSerializable()
class WalletTransactionEntity {
  final String id;
  final String? orderId;
  final int amount;
  @JsonKey(unknownEnumValue: WalletBalanceKind.available)
  final WalletBalanceKind kind;
  @JsonKey(unknownEnumValue: WalletEntryReason.adjustment)
  final WalletEntryReason reason;
  final String? productTitle;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.amount,
    required this.kind,
    required this.reason,
    required this.createdAt,
    this.orderId,
    this.productTitle,
  });

  factory WalletTransactionEntity.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionEntityFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionEntityToJson(this);

  bool get isCredit => amount > 0;

  bool get isPending => kind == WalletBalanceKind.pending;

  String get label {
    final title = productTitle;
    if (title != null && title.isNotEmpty) return '${reason.label} · $title';
    return reason.label;
  }
}
