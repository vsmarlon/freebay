import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

part 'comment_entity.g.dart';

@JsonSerializable()
class CommentEntity extends Equatable {
  final String id;
  final String content;
  final String userId;
  final String postId;
  final String? parentId;
  final DateTime createdAt;
  final UserEntity? user; // Backend might optionally join user data

  @JsonKey(defaultValue: [])
  final List<CommentEntity> replies;

  const CommentEntity({
    required this.id,
    required this.content,
    required this.userId,
    required this.postId,
    this.parentId,
    required this.createdAt,
    this.user,
    this.replies = const [],
  });

  factory CommentEntity.fromJson(Map<String, dynamic> json) =>
      _$CommentEntityFromJson(json);
  Map<String, dynamic> toJson() => _$CommentEntityToJson(this);

  CommentEntity copyWith({
    String? id,
    String? content,
    String? userId,
    String? postId,
    String? parentId,
    DateTime? createdAt,
    UserEntity? user,
    List<CommentEntity>? replies,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        userId,
        postId,
        parentId,
        createdAt,
        user,
        replies,
      ];
}
