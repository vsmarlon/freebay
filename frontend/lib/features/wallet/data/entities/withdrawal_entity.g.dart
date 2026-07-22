// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawalEntity _$WithdrawalEntityFromJson(Map<String, dynamic> json) =>
    WithdrawalEntity(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WithdrawalEntityToJson(WithdrawalEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };
