// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_status_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectStatusEntity _$ConnectStatusEntityFromJson(Map<String, dynamic> json) =>
    ConnectStatusEntity(
      status: $enumDecode(_$ConnectStatusEnumMap, json['status']),
      requirementsDue:
          (json['requirementsDue'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ConnectStatusEntityToJson(
  ConnectStatusEntity instance,
) => <String, dynamic>{
  'status': _$ConnectStatusEnumMap[instance.status]!,
  'requirementsDue': instance.requirementsDue,
};

const _$ConnectStatusEnumMap = {
  ConnectStatus.onboardingRequired: 'onboarding-required',
  ConnectStatus.requirementsDue: 'requirements-due',
  ConnectStatus.restricted: 'restricted',
  ConnectStatus.transferReady: 'transfer-ready',
};
