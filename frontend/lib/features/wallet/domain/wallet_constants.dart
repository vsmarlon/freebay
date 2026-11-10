import 'package:json_annotation/json_annotation.dart';

enum WalletBalanceKind {
  @JsonValue('AVAILABLE')
  available,
  @JsonValue('PENDING')
  pending,
  @JsonValue('TOTAL_EARNED')
  totalEarned,
}

enum WalletEntryReason {
  @JsonValue('SALE_HELD')
  saleHeld('Venda em custódia'),
  @JsonValue('SALE_RELEASED')
  saleReleased('Venda liberada'),
  @JsonValue('HOLD_RELEASED')
  holdReleased('Custódia encerrada'),
  @JsonValue('REFUND')
  refund('Reembolso'),
  @JsonValue('DISPUTE_REFUND')
  disputeRefund('Reembolso por disputa'),
  @JsonValue('DISPUTE_RELEASE')
  disputeRelease('Disputa resolvida'),
  @JsonValue('PAYOUT')
  payout('Repasse enviado'),
  @JsonValue('WITHDRAWAL')
  withdrawal('Saque'),
  @JsonValue('ADJUSTMENT')
  adjustment('Ajuste');

  const WalletEntryReason(this.label);

  final String label;
}
