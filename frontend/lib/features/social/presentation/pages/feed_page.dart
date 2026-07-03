import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/create_composer_sheet.dart';
import 'package:freebay/core/components/app_refresh_indicator.dart';
import 'package:freebay/core/components/app_shell_scaffold_key.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/social/presentation/widgets/feed_filters.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true;

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
              feedType:
                  feedType == FeedType.following ? 'following' : 'explore',
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
    super.build(context);
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'FREEBAY',
            exclamation: '!',
            leading: GestureDetector(
              onTap: () => appShellScaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(Icons.menu, color: context.textPrimary, size: 20),
              ),
            ),
            actions: [
              _HeaderIcon(
                icon: Icons.notifications_outlined,
                route: '/notifications',
              ),
              _HeaderIcon(
                icon: Icons.account_balance_wallet_outlined,
                route: '/wallet',
              ),
            ],
          ),
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
                feedType: type == FeedType.following ? 'following' : 'explore',
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

    return AppRefreshIndicator(
      onRefresh: () async {
        final type = ref.read(feedTypeProvider);
        ref.read(feedProvider.notifier).loadFeed(
              refresh: true,
              feedType: type == FeedType.following ? 'following' : 'explore',
            );
      },
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filteredPosts.length + 1 + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _buildFeedTitle(feedType, contentFilter),
                Spacing.vSm,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              FeedTypeDropdown(
                currentType: feedType,
                onChanged: _onFeedTypeChanged,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: FeedContentFilterBar(
              currentFilter: contentFilter,
              onChanged: (filter) =>
                  ref.read(feedContentFilterProvider.notifier).state = filter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _SkeletonFeedPost(),
          SizedBox(height: 12),
          _SkeletonFeedPost(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return GestureDetector(
      onTap: _openCreateChooser,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(
                Icons.person,
                size: 14,
                color: AppColors.onPrimary,
              ),
            ),
            Spacing.hSm,
            Expanded(
              child: Text(
                'Criar post social ou anuncio de venda',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
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
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      builder: (_) => const CreateComposerSheet(),
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

class _SkeletonFeedPost extends StatelessWidget {
  const _SkeletonFeedPost();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShimmerBlock(width: 48, height: 48),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(height: 14, width: 100),
                SizedBox(height: 8),
                ShimmerBlock(height: 12, width: 150),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        ShimmerBlock(height: 200),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String route;

  const _HeaderIcon({required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor, width: 2),
        ),
        child: Icon(icon, color: context.textPrimary, size: 20),
      ),
    );
  }
}
