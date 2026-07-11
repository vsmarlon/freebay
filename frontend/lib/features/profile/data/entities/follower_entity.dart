import 'package:freezed_annotation/freezed_annotation.dart';

part 'follower_entity.freezed.dart';
part 'follower_entity.g.dart';

@freezed
abstract class FollowerEntity with _$FollowerEntity {
  const factory FollowerEntity({
    required String id,
    @Default('Usuário') String displayName,
    String? avatarUrl,
    @Default(false) bool isVerified,
    String? bio,
    @Default(false) bool isFollowing,
  }) = _FollowerEntity;

  factory FollowerEntity.fromJson(Map<String, dynamic> json) =>
      _$FollowerEntityFromJson(json);
}
