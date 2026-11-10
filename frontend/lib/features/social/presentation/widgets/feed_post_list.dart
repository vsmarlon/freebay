import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
          message: l10n(context).commonTryAgainLater,
          onRetry: onRetry,
        ),
      );
    }
    if (state.posts.isEmpty && !state.isLoading) {
      return SliverFillRemaining(hasScrollBody: false, child: emptyState);
    }
    if (state.posts.isEmpty && state.isLoading) {
      return ShimmerScope(
        child: SliverList.builder(
          itemCount: 3,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(height: 52),
                Spacing.vSm,
                ShimmerBlock(height: 200),
                Spacing.vSm,
                ShimmerBlock(height: 44),
              ],
            ),
          ),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
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
        ),
        if (state.error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: l10n(context).commonRetry,
                onPressed: onRetry,
              ),
            ),
          ),
      ],
    );
  }
}
