import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_stats_entity.g.dart';

@JsonSerializable()
class UserStatsEntity extends Equatable {
  @JsonKey(defaultValue: 0)
  final int salesCount;
  @JsonKey(defaultValue: 0)
  final int purchasesCount;
  @JsonKey(defaultValue: 0)
  final int followersCount;
  @JsonKey(defaultValue: 0)
  final int followingCount;

  const UserStatsEntity({
    required this.salesCount,
    required this.purchasesCount,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserStatsEntity.fromJson(Map<String, dynamic> json) =>
      _$UserStatsEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatsEntityToJson(this);

  @override
  List<Object?> get props =>
      [salesCount, purchasesCount, followersCount, followingCount];
}
