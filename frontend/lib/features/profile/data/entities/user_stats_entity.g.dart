// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStatsEntity _$UserStatsEntityFromJson(Map<String, dynamic> json) =>
    UserStatsEntity(
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      purchasesCount: (json['purchasesCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserStatsEntityToJson(UserStatsEntity instance) =>
    <String, dynamic>{
      'salesCount': instance.salesCount,
      'purchasesCount': instance.purchasesCount,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
    };
