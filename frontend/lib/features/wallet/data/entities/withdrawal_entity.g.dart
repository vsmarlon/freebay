// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawalEntity _$WithdrawalEntityFromJson(Map<String, dynamic> json) =>
    WithdrawalEntity(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      status: $enumDecode(
        _$WithdrawalStatusEnumMap,
        json['status'],
        unknownValue: WithdrawalStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WithdrawalEntityToJson(WithdrawalEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'status': _$WithdrawalStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$WithdrawalStatusEnumMap = {
  WithdrawalStatus.pending: 'PENDING',
  WithdrawalStatus.processing: 'PROCESSING',
  WithdrawalStatus.completed: 'COMPLETED',
  WithdrawalStatus.failed: 'FAILED',
};
