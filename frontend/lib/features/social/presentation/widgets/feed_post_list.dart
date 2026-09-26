import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';

class FeedPostList extends StatelessWidget {
  final FeedState state;
  final VoidCallback onRetry;
  final Widget emptyState;

  const FeedPostList({
    super.key,
    required this.state,
    required this.onRetry,
    required this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    if (state.error != null && state.posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState.error(
          message: 'Verifique sua conexão e tente novamente',
          onRetry: onRetry,
        ),
      );
    }
    if (state.posts.isEmpty && !state.isLoading) {
      return SliverFillRemaining(hasScrollBody: false, child: emptyState);
    }
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => RepaintBoundary(
            key: ValueKey('post_${state.posts[index].id}'),
            child: FeedPostItem(post: state.posts[index]),
          ),
          childCount: state.posts.length,
        ),
      ),
    );
  }
}
