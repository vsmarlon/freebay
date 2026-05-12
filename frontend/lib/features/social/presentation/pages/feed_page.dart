import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/freebay.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/create_composer_sheet.dart';
import 'package:freebay/features/social/presentation/widgets/feed_filters.dart';
import 'package:freebay/features/social/presentation/widgets/feed_header.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:freebay/features/social/presentation/widgets/stories_row.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    _animationController.forward();

    // ref.read is allowed in initState() per Riverpod docs — one-time seeding.
    final currentState = ref.read(feedProvider);
    final feedType = ref.read(feedTypeProvider);
    if (currentState.posts.isEmpty && !currentState.isLoading) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(feedProvider.notifier).loadFeed(
              refresh: true,
              feedType: feedType == FeedType.following ? 'following' : 'explore',
            );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFeedTypeChanged(FeedType type) {
    ref.read(feedTypeProvider.notifier).state = type;
    ref.read(feedProvider.notifier).loadFeed(
          refresh: true,
          feedType: type == FeedType.following ? 'following' : 'explore',
        );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: context.surfaceMidColor,
      body: Column(
        children: [
          const FeedHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBody(feedState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(FeedState feedState) {
    final feedType = ref.watch(feedTypeProvider);
    final contentFilter = ref.watch(feedContentFilterProvider);
    final filteredPosts = feedState.posts
        .where((post) => _matchesContentFilter(post, contentFilter))
        .toList();

    if (feedState.error != null && feedState.posts.isEmpty) {
      return EmptyState.error(
        message: 'Verifique sua conexão e tente novamente',
        onRetry: () {
          final type = ref.read(feedTypeProvider);
          ref.read(feedProvider.notifier).loadFeed(
                refresh: true,
                feedType:
                    type == FeedType.following ? 'following' : 'explore',
              );
        },
      );
    }

    if (feedState.posts.isEmpty && !feedState.isLoading) {
      return EmptyState.noPosts();
    }

    if (filteredPosts.isEmpty && !feedState.isLoading) {
      return EmptyState.noResults(
        subtitle: 'Troque entre posts sociais e vendas quando quiser.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final type = ref.read(feedTypeProvider);
        ref.read(feedProvider.notifier).loadFeed(
              refresh: true,
              feedType: type == FeedType.following ? 'following' : 'explore',
            );
      },
      color: AppColors.primaryContainer,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filteredPosts.length + 1 + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _buildFeedTitle(feedType, contentFilter),
                const StoriesRow(),
                _buildInputArea(),
              ],
            );
          }
          if (index == filteredPosts.length + 1) {
            return _buildLoadingMore();
          }
          return FeedPostItem(post: filteredPosts[index - 1]);
        },
      ),
    );
  }

  Widget _buildFeedTitle(
    FeedType feedType,
    FeedContentFilter contentFilter,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'FEED',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                  height: 0.9,
                  color: context.textPrimary,
                ),
              ),
              Freebay.horizontalSpacing8,
              FeedTypeDropdown(
                currentType: feedType,
                onChanged: _onFeedTypeChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FeedContentFilterBar(
            currentFilter: contentFilter,
            onChanged: (filter) =>
                ref.read(feedContentFilterProvider.notifier).state = filter,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppColors.primaryContainer,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return GestureDetector(
      onTap: _openCreateChooser,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border.all(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 14,
                color: Colors.white,
              ),
            ),
            Freebay.horizontalSpacing8,
            Expanded(
              child: Text(
                'Criar post social ou anuncio de venda',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.outline,
                ),
              ),
            ),
            const Icon(
              Icons.add,
              color: AppColors.primaryContainer,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateChooser() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateComposerSheet(),
    );
  }

  bool _matchesContentFilter(
    PostEntity post,
    FeedContentFilter contentFilter,
  ) {
    switch (contentFilter) {
      case FeedContentFilter.socialOnly:
        return post.type != 'PRODUCT';
      case FeedContentFilter.sellingOnly:
        return post.type == 'PRODUCT';
      case FeedContentFilter.all:
        return true;
    }
  }
}