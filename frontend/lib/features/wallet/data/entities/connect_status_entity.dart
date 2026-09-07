import 'package:json_annotation/json_annotation.dart';

part 'connect_status_entity.g.dart';

@JsonSerializable()
class ConnectStatusEntity {
  final bool onboarded;
  final bool transfersEnabled;
  final bool payoutsEnabled;
  final List<String> requirementsDue;

  const ConnectStatusEntity({
    required this.onboarded,
    required this.transfersEnabled,
    required this.payoutsEnabled,
    this.requirementsDue = const [],
  });

  factory ConnectStatusEntity.fromJson(Map<String, dynamic> json) =>
      _$ConnectStatusEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectStatusEntityToJson(this);

  bool get canReceive => onboarded && transfersEnabled;
}
