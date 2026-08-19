import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

class UserPostEntry {
  final PostEntity post;
  final DateTime? repostedAt;
  final UserEntity? repostedBy;
  final bool isReposted;
  final int? sharesCount;

  const UserPostEntry({
    required this.post,
    this.repostedAt,
    this.repostedBy,
    this.isReposted = false,
    this.sharesCount,
  });

  factory UserPostEntry.fromJson(Map<String, dynamic> json) => UserPostEntry(
    post: PostEntity.fromJson(json['post'] as Map<String, dynamic>),
    repostedAt: json['repostedAt'] != null
        ? DateTime.parse(json['repostedAt'] as String)
        : null,
    repostedBy: json['repostedBy'] != null
        ? UserEntity.fromJson(json['repostedBy'] as Map<String, dynamic>)
        : null,
    isReposted: json['isReposted'] as bool? ?? false,
    sharesCount: json['sharesCount'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'post': post.toJson(),
    'repostedAt': repostedAt?.toIso8601String(),
    'repostedBy': repostedBy?.toJson(),
    'isReposted': isReposted,
    'sharesCount': sharesCount,
  };

  PostEntity toPostEntity() {
    return post.copyWith(
      repostedAt: repostedAt,
      repostedBy: repostedBy,
      hasReposted: isReposted,
      sharesCount: sharesCount ?? post.sharesCount,
    );
  }
}
