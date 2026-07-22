import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/wallet/domain/wallet_constants.dart';

part 'withdrawal_entity.g.dart';

@JsonSerializable()
class WithdrawalEntity {
  final String id;
  final int amount;
  @JsonKey(unknownEnumValue: WithdrawalStatus.pending)
  final WithdrawalStatus status;
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
}
