// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserEntity _$UserEntityFromJson(Map<String, dynamic> json) => UserEntity(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isGuest: json['isGuest'] as bool? ?? false,
      hasCpf: json['hasCpf'] as bool? ?? false,
      reputationScore: json['reputationScore'] as num? ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      purchasesCount: (json['purchasesCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      hasActiveStory: json['hasActiveStory'] as bool? ?? false,
    );

Map<String, dynamic> _$UserEntityToJson(UserEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'bannerUrl': instance.bannerUrl,
      'bio': instance.bio,
      'city': instance.city,
      'state': instance.state,
      'isVerified': instance.isVerified,
      'isGuest': instance.isGuest,
      'hasCpf': instance.hasCpf,
      'reputationScore': instance.reputationScore,
      'totalReviews': instance.totalReviews,
      'salesCount': instance.salesCount,
      'purchasesCount': instance.purchasesCount,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
      'postsCount': instance.postsCount,
      'productsCount': instance.productsCount,
      'hasActiveStory': instance.hasActiveStory,
    };
