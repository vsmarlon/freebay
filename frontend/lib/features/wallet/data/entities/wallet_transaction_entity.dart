import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/wallet/domain/wallet_constants.dart';

part 'wallet_transaction_entity.g.dart';

@JsonSerializable()
class WalletTransactionEntity {
  final String id;
  final String orderId;
  final int amount;
  final String status;
  @JsonKey(unknownEnumValue: WalletTransactionType.purchase)
  final WalletTransactionType type;
  final String? productTitle;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.type,
    required this.createdAt,
    this.productTitle,
  });

  factory WalletTransactionEntity.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionEntityFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionEntityToJson(this);

  bool get isCredit => type.isCredit;

  String get label {
    final prefix = isCredit ? 'Venda' : 'Compra';
    final title = productTitle;
    if (title != null && title.isNotEmpty) return '$prefix · $title';
    return prefix;
  }
}
