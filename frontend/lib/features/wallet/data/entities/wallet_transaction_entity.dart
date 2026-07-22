import 'package:json_annotation/json_annotation.dart';

part 'wallet_transaction_entity.g.dart';

@JsonSerializable()
class WalletTransactionEntity {
  final String id;
  final String orderId;
  final int amount;
  final String status;
  final String type;
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

  bool get isCredit => type == 'SALE';

  String get label {
    final title = productTitle;
    if (title != null && title.isNotEmpty) {
      return isCredit ? 'Venda · $title' : 'Compra · $title';
    }
    return isCredit ? 'Venda' : 'Compra';
  }
}
