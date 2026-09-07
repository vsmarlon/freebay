// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_post_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPostEntry _$UserPostEntryFromJson(Map<String, dynamic> json) =>
    UserPostEntry(
      post: PostEntity.fromJson(json['post'] as Map<String, dynamic>),
      repostedAt: json['repostedAt'] == null
          ? null
          : DateTime.parse(json['repostedAt'] as String),
      repostedBy: json['repostedBy'] == null
          ? null
          : UserEntity.fromJson(json['repostedBy'] as Map<String, dynamic>),
      isReposted: json['isReposted'] as bool? ?? false,
      sharesCount: (json['sharesCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserPostEntryToJson(UserPostEntry instance) =>
    <String, dynamic>{
      'post': instance.post.toJson(),
      'repostedAt': instance.repostedAt?.toIso8601String(),
      'repostedBy': instance.repostedBy?.toJson(),
      'isReposted': instance.isReposted,
      'sharesCount': instance.sharesCount,
    };
