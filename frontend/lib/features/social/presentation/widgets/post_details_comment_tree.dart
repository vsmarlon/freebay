import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';

class PostDetailsCommentTree extends StatelessWidget {
  final TreeNode<CommentEntity> tree;
  final double height;
  final Widget Function(BuildContext, CommentEntity) itemBuilder;

  const PostDetailsCommentTree({
    super.key,
    required this.tree,
    required this.height,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TreeView.simple<CommentEntity>(
        tree: tree,
        showRootNode: false,
        expansionIndicatorBuilder: (context, node) =>
            ChevronIndicator.rightDown(
              tree: node,
              color: context.textPrimary,
              padding: const EdgeInsets.all(8),
            ),
        indentation: const Indentation(),
        builder: (context, node) {
          final comment = node.data;
          return comment == null
              ? const SizedBox.shrink()
              : itemBuilder(context, comment);
        },
      ),
    );
  }
}
