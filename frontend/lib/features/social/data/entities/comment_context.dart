import 'package:freebay/features/social/data/entities/comment_entity.dart';

class CommentContext {
  final List<CommentEntity> ancestors;
  final CommentEntity focus;
  final List<CommentEntity> replies;
  final String? nextReplyCursor;
  final String? nextAncestorCursor;

  const CommentContext({
    required this.ancestors,
    required this.focus,
    required this.replies,
    this.nextReplyCursor,
    this.nextAncestorCursor,
  });

  factory CommentContext.fromJson(Map<String, dynamic> json) {
    final focus = json['focus'];
    if (focus is! Map) throw const FormatException('Missing focus comment');
    return CommentContext(
      ancestors: _comments(json['ancestors']),
      focus: CommentEntity.fromJson(Map<String, dynamic>.from(focus)),
      replies: _comments(json['replies']),
      nextReplyCursor: json['nextReplyCursor'] as String?,
      nextAncestorCursor: json['nextAncestorCursor'] as String?,
    );
  }

  static List<CommentEntity> _comments(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map(
              (item) => CommentEntity.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false)
      : const [];
}
