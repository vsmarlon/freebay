import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_search_entity.freezed.dart';
part 'user_search_entity.g.dart';

@freezed
abstract class UserSearchEntity with _$UserSearchEntity {
  const factory UserSearchEntity({
    required String id,
    required String displayName,
    String? avatarUrl,
    String? bio,
    @Default(false) bool isVerified,
    @Default(0.0) double reputationScore,
    @Default(0) int totalReviews,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
  }) = _UserSearchEntity;

  factory UserSearchEntity.fromJson(Map<String, dynamic> json) =>
      _$UserSearchEntityFromJson(json);
}
