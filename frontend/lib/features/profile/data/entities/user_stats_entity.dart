import 'package:equatable/equatable.dart';

class UserStatsEntity extends Equatable {
  final int salesCount;
  final int purchasesCount;
  final int followersCount;
  final int followingCount;

  const UserStatsEntity({
    required this.salesCount,
    required this.purchasesCount,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserStatsEntity.fromJson(Map<String, dynamic> json) {
    return UserStatsEntity(
      salesCount: json['salesCount'] as int? ?? 0,
      purchasesCount: json['purchasesCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'salesCount': salesCount,
        'purchasesCount': purchasesCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
      };

  @override
  List<Object?> get props =>
      [salesCount, purchasesCount, followersCount, followingCount];
}
