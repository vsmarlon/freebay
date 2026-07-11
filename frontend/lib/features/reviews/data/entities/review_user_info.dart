import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_user_info.freezed.dart';
part 'review_user_info.g.dart';

@freezed
abstract class ReviewUserInfo with _$ReviewUserInfo {
  const ReviewUserInfo._();

  const factory ReviewUserInfo({
    required String id,
    String? displayName,
    String? avatarUrl,
  }) = _ReviewUserInfo;

  factory ReviewUserInfo.fromJson(Map<String, dynamic> json) =>
      _$ReviewUserInfoFromJson(json);

  String get displayNameOrDefault => displayName ?? 'Usuário';
}
