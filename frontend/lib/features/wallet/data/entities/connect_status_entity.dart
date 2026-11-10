import 'package:json_annotation/json_annotation.dart';

part 'connect_status_entity.g.dart';

enum ConnectStatus {
  @JsonValue('onboarding-required')
  onboardingRequired,
  @JsonValue('requirements-due')
  requirementsDue,
  @JsonValue('restricted')
  restricted,
  @JsonValue('transfer-ready')
  transferReady,
}

@JsonSerializable()
class ConnectStatusEntity {
  final ConnectStatus status;
  final List<String> requirementsDue;

  const ConnectStatusEntity({
    required this.status,
    this.requirementsDue = const [],
  });

  factory ConnectStatusEntity.fromJson(Map<String, dynamic> json) =>
      _$ConnectStatusEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectStatusEntityToJson(this);

  bool get canReceive => status == ConnectStatus.transferReady;
}
