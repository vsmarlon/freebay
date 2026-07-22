import 'package:json_annotation/json_annotation.dart';

class WalletConstants {
  WalletConstants._();

  /// Mirrors MIN_WITHDRAWAL in nest-backend withdraw.usecase.ts.
  static const int minWithdrawalCents = 2000;
}

enum PixKeyType {
  cpf('CPF', 'CPF'),
  email('EMAIL', 'E-mail'),
  phone('PHONE', 'Telefone'),
  random('RANDOM', 'Aleatória');

  const PixKeyType(this.wireValue, this.label);

  final String wireValue;
  final String label;
}

enum WalletTransactionType {
  @JsonValue('PURCHASE')
  purchase,
  @JsonValue('SALE')
  sale;

  bool get isCredit => this == WalletTransactionType.sale;
}

enum WithdrawalStatus {
  @JsonValue('PENDING')
  pending('Pendente'),
  @JsonValue('PROCESSING')
  processing('Processando'),
  @JsonValue('COMPLETED')
  completed('Concluído'),
  @JsonValue('FAILED')
  failed('Falhou');

  const WithdrawalStatus(this.label);

  final String label;
}
