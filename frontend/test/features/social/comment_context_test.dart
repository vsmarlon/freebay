import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/entities/comment_context.dart';

void main() {
  test('decodes focused comment context and independent paging cursors', () {
    final context = CommentContext.fromJson({
      'ancestors': [_comment('parent', parentId: null)],
      'focus': _comment('focus', parentId: 'parent'),
      'replies': [_comment('reply', parentId: 'focus')],
      'nextReplyCursor': 'reply-next',
      'nextAncestorCursor': 'ancestor-next',
    });

    expect(context.ancestors.single.id, 'parent');
    expect(context.focus.parentId, 'parent');
    expect(context.replies.single.parentId, 'focus');
    expect(context.nextReplyCursor, 'reply-next');
    expect(context.nextAncestorCursor, 'ancestor-next');
  });
}

Map<String, Object?> _comment(String id, {required String? parentId}) => {
  'id': id,
  'content': 'content $id',
  'userId': 'user',
  'postId': 'post',
  'parentId': parentId,
  'createdAt': '2026-10-14T12:00:00.000Z',
};
