import 'package:json_annotation/json_annotation.dart';

part 'withdrawal_entity.g.dart';

@JsonSerializable()
class WithdrawalEntity {
  final String id;
  final int amount;
  final String status;
  final DateTime createdAt;

  const WithdrawalEntity({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawalEntity.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalEntityFromJson(json);

  Map<String, dynamic> toJson() => _$WithdrawalEntityToJson(this);

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pendente';
      case 'PROCESSING':
        return 'Processando';
      case 'COMPLETED':
        return 'Concluído';
      case 'FAILED':
        return 'Falhou';
      default:
        return status;
    }
  }
}
