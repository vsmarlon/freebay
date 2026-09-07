import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/create_composer_sheet.dart';
import 'package:freebay/features/social/presentation/widgets/feed_filters.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:freebay/features/social/presentation/widgets/stories_row.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppMotion.base,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppMotion.baseCurve,
    );
    _animationController.forward();

    _scrollController.addListener(_onScroll);

    final currentState = ref.read(feedProvider);
    final feedType = ref.read(feedTypeProvider);
    final contentFilter = ref.read(feedContentFilterProvider);
    if (currentState.posts.isEmpty && !currentState.isLoading) {
      Future.microtask(() {
        if (!mounted) return;
        ref
            .read(feedProvider.notifier)
            .loadFeed(
              refresh: true,
              feedType: feedType == FeedType.following
                  ? 'following'
                  : 'explore',
              contentFilter: contentFilter.apiValue,
            );
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFeedTypeChanged(FeedType type) {
    ref.read(feedTypeProvider.notifier).set(type);
    final contentFilter = ref.read(feedContentFilterProvider);
    ref
        .read(feedProvider.notifier)
        .loadFeed(
          refresh: true,
          feedType: type == FeedType.following ? 'following' : 'explore',
          contentFilter: contentFilter.apiValue,
        );
  }

  void _onContentFilterChanged(FeedContentFilter filter) {
    ref.read(feedContentFilterProvider.notifier).set(filter);
    final feedType = ref.read(feedTypeProvider);
    ref
        .read(feedProvider.notifier)
        .loadFeed(
          refresh: true,
          feedType: feedType == FeedType.following ? 'following' : 'explore',
          contentFilter: filter.apiValue,
        );
  }

  void _loadMore() {
    final feedType = ref.read(feedTypeProvider);
    final contentFilter = ref.read(feedContentFilterProvider);
    ref
        .read(feedProvider.notifier)
        .loadFeed(
          feedType: feedType == FeedType.following ? 'following' : 'explore',
          contentFilter: contentFilter.apiValue,
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final feedState = ref.watch(feedProvider);
    final feedType = ref.watch(feedTypeProvider);
    final contentFilter = ref.watch(feedContentFilterProvider);
    final posts = feedState.posts;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: AppRefreshIndicator(
          onRefresh: () async {
            final type = ref.read(feedTypeProvider);
            final filter = ref.read(feedContentFilterProvider);
            await ref
                .read(feedProvider.notifier)
                .loadFeed(
                  refresh: true,
                  feedType: type == FeedType.following
                      ? 'following'
                      : 'explore',
                  contentFilter: filter.apiValue,
                );
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Floating and snapping SliverAppBar to free all screen when scrolling
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: context.appBarColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.5),
                  child: Container(
                    color: context.borderColor.withAlpha(50),
                    height: 1.5,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: BrutalistIconButton(
                      icon: Icons.menu,
                      size: 38,
                      onTap: () =>
                          appShellScaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                ),
                title: RichText(
                  text: TextSpan(
                    text: 'FREEBAY',
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                      color: context.textPrimary,
                    ),
                    children: const [
                      TextSpan(
                        text: '!',
                        style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  const _HeaderIcon(
                    icon: Icons.person_search_outlined,
                    route: AppRoutes.peopleSearch,
                  ),
                  const SizedBox(width: 8),
                  const _HeaderIcon(
                    icon: Icons.notifications_outlined,
                    route: '/notifications',
                  ),
                  const SizedBox(width: 8),
                  const _HeaderIcon(
                    icon: Icons.account_balance_wallet_outlined,
                    route: '/wallet',
                    useGo: true,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Spacing.vMd,
                    const StoriesRow(),
                    Spacing.vSm,
                    _buildFeedTitle(feedType, contentFilter),
                    Spacing.vSm,
                    _buildInputArea(),
                  ],
                ),
              ),
              if (feedState.error != null && posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState.error(
                    message: 'Verifique sua conexão e tente novamente',
                    onRetry: () {
                      final type = ref.read(feedTypeProvider);
                      final filter = ref.read(feedContentFilterProvider);
                      ref
                          .read(feedProvider.notifier)
                          .loadFeed(
                            refresh: true,
                            feedType: type == FeedType.following
                                ? 'following'
                                : 'explore',
                            contentFilter: filter.apiValue,
                          );
                    },
                  ),
                )
              else if (posts.isEmpty && !feedState.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: contentFilter == FeedContentFilter.all
                      ? EmptyState.noPosts()
                      : EmptyState.noResults(
                          subtitle:
                              'Troque entre posts sociais e vendas quando quiser.',
                        ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return RepaintBoundary(
                        child: FeedPostItem(post: posts[index]),
                      );
                    }, childCount: posts.length),
                  ),
                ),
                if (feedState.hasMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTitle(
    FeedType currentType,
    FeedContentFilter contentFilter,
  ) {
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<FeedType>(
            initialValue: currentType,
            onSelected: _onFeedTypeChanged,
            offset: const Offset(0, 40),
            color: context.isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: context.borderColor, width: 2),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FeedType.explore,
                child: Row(
                  children: [
                    Icon(
                      Icons.explore,
                      color: currentType == FeedType.explore
                          ? AppColors.primaryContainer
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EXPLORAR',
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontWeight: currentType == FeedType.explore
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: currentType == FeedType.explore
                            ? AppColors.primaryContainer
                            : context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FeedType.following,
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: currentType == FeedType.following
                          ? AppColors.primaryContainer
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SEGUINDO',
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontWeight: currentType == FeedType.following
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: currentType == FeedType.following
                            ? AppColors.primaryContainer
                            : context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceContainerLow,
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentType == FeedType.explore
                        ? Icons.explore
                        : Icons.people,
                    size: 16,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentType == FeedType.explore ? 'EXPLORE' : 'SEGUINDO',
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: context.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FeedContentFilterBar(
          currentFilter: contentFilter,
          onChanged: _onContentFilterChanged,
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          showBrutalistSheet(
            context: context,
            title: 'CRIAR PUBLICAÇÃO',
            child: const CreateComposerSheet(),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border.all(color: context.borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                color: AppColors.primaryContainer,
                child: const Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Criar post social ou anúncio de venda',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: context.textSecondary,
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
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String route;
  final bool useGo;

  const _HeaderIcon({
    required this.icon,
    required this.route,
    this.useGo = false,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalistIconButton(
      icon: icon,
      size: 38,
      onTap: () {
        if (useGo) {
          context.go(route);
        } else {
          context.push(route);
        }
      },
    );
  }
}
