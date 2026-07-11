import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats_entity.freezed.dart';
part 'user_stats_entity.g.dart';

@freezed
abstract class UserStatsEntity with _$UserStatsEntity {
  const factory UserStatsEntity({
    @Default(0) int salesCount,
    @Default(0) int purchasesCount,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
  }) = _UserStatsEntity;

  factory UserStatsEntity.fromJson(Map<String, dynamic> json) =>
      _$UserStatsEntityFromJson(json);
}
