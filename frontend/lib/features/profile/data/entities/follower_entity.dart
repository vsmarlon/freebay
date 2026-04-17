import 'package:equatable/equatable.dart';

class FollowerEntity extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final String? bio;
  final bool isFollowing;

  const FollowerEntity({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.isVerified,
    this.bio,
    required this.isFollowing,
  });

  factory FollowerEntity.fromJson(Map<String, dynamic> json) {
    return FollowerEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Usuário',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      bio: json['bio'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'bio': bio,
        'isFollowing': isFollowing,
      };

  @override
  List<Object?> get props =>
      [id, displayName, avatarUrl, isVerified, bio, isFollowing];
}
