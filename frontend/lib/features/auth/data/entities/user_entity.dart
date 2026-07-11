import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const UserEntity._();

  const factory UserEntity({
    required String id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    String? city,
    String? state,
    @Default(false) bool isVerified,
    @Default(false) bool isGuest,
    @Default(false) bool hasCpf,
    String? cpf,
    @Default(0) num reputationScore,
    @Default(0) int totalReviews,
    @Default(0) int salesCount,
    @Default(0) int purchasesCount,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int postsCount,
    @Default(0) int productsCount,
    @Default(false) bool hasActiveStory,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);

  String get displayNameOrDefault =>
      displayName ?? (isGuest ? 'Convidado' : 'Usuário');
}
