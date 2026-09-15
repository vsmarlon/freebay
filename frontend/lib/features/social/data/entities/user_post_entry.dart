import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_post_entry.g.dart';

@JsonSerializable()
class UserPostEntry {
  final PostEntity post;
  final String? repostId;
  final DateTime? repostedAt;
  final UserEntity? repostedBy;
  final bool isReposted;
  final int? sharesCount;

  const UserPostEntry({
    required this.post,
    this.repostId,
    this.repostedAt,
    this.repostedBy,
    this.isReposted = false,
    this.sharesCount,
  });

  factory UserPostEntry.fromJson(Map<String, dynamic> json) =>
      _$UserPostEntryFromJson(json);

  Map<String, dynamic> toJson() => _$UserPostEntryToJson(this);

  PostEntity toPostEntity() {
    return post.copyWith(
      repostedAt: repostedAt,
      repostedBy: repostedBy,
      hasReposted: isReposted,
      sharesCount: sharesCount ?? post.sharesCount,
    );
  }
}
