import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

part 'post_entity.freezed.dart';
part 'post_entity.g.dart';

@freezed
abstract class PostProductInfo with _$PostProductInfo {
  const factory PostProductInfo({
    required String id,
    required String title,
    required String description,
    required int price,
    required String condition,
  }) = _PostProductInfo;

  factory PostProductInfo.fromJson(Map<String, dynamic> json) =>
      _$PostProductInfoFromJson(json);
}

@freezed
abstract class PostEntity with _$PostEntity {
  const PostEntity._();

  const factory PostEntity({
    required String id,
    required String userId,
    String? content,
    String? imageUrl,
    @Default('REGULAR') String type,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(0) int sharesCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
    @Default(false) bool hasReposted,
    DateTime? repostedAt,
    UserEntity? repostedBy,
    required DateTime createdAt,
    required UserEntity user,
    PostProductInfo? product,
  }) = _PostEntity;

  factory PostEntity.fromJson(Map<String, dynamic> json) =>
      _$PostEntityFromJson(json);
}
