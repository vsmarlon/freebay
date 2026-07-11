import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

part 'comment_entity.freezed.dart';
part 'comment_entity.g.dart';

@freezed
abstract class CommentEntity with _$CommentEntity {
  const factory CommentEntity({
    required String id,
    required String content,
    required String userId,
    required String postId,
    String? parentId,
    @Default(0) int likesCount,
    @Default(false) bool isLiked,
    required DateTime createdAt,
    UserEntity? user,
    @Default([]) List<CommentEntity> replies,
  }) = _CommentEntity;

  factory CommentEntity.fromJson(Map<String, dynamic> json) =>
      _$CommentEntityFromJson(json);
}
