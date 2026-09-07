// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_status_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectStatusEntity _$ConnectStatusEntityFromJson(Map<String, dynamic> json) =>
    ConnectStatusEntity(
      onboarded: json['onboarded'] as bool,
      transfersEnabled: json['transfersEnabled'] as bool,
      payoutsEnabled: json['payoutsEnabled'] as bool,
      requirementsDue:
          (json['requirementsDue'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ConnectStatusEntityToJson(
  ConnectStatusEntity instance,
) => <String, dynamic>{
  'onboarded': instance.onboarded,
  'transfersEnabled': instance.transfersEnabled,
  'payoutsEnabled': instance.payoutsEnabled,
  'requirementsDue': instance.requirementsDue,
};
