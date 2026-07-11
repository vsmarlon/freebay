import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

part 'user_post_entry.freezed.dart';
part 'user_post_entry.g.dart';

@freezed
abstract class UserPostEntry with _$UserPostEntry {
  const UserPostEntry._();

  const factory UserPostEntry({
    required PostEntity post,
    DateTime? repostedAt,
    UserEntity? repostedBy,
    @Default(false) bool isReposted,
    int? sharesCount,
  }) = _UserPostEntry;

  factory UserPostEntry.fromJson(Map<String, dynamic> json) =>
      _$UserPostEntryFromJson(json);

  PostEntity toPostEntity() {
    return post.copyWith(
      repostedAt: repostedAt,
      repostedBy: repostedBy,
      hasReposted: isReposted,
      sharesCount: sharesCount ?? post.sharesCount,
    );
  }
}
