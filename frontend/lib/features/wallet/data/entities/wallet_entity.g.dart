// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletEntity _$WalletEntityFromJson(Map<String, dynamic> json) =>
    _WalletEntity(
      availableBalance: (json['availableBalance'] as num?)?.toInt() ?? 0,
      pendingBalance: (json['pendingBalance'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WalletEntityToJson(_WalletEntity instance) =>
    <String, dynamic>{
      'availableBalance': instance.availableBalance,
      'pendingBalance': instance.pendingBalance,
      'balance': instance.balance,
    };
