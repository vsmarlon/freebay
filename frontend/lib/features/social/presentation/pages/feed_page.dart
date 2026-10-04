import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/create_composer_sheet.dart';
import 'package:freebay/features/social/presentation/widgets/feed_header.dart';
import 'package:freebay/features/social/presentation/widgets/feed_intro_sections.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_list.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
    if (currentState.posts.isEmpty && !currentState.isLoading) {
      Future.microtask(() {
        if (!mounted) return;
        _loadCurrentFeed(refresh: true);
      });
    }
  }

  void _onScroll() {
    if (ref.read(feedProvider).error == null &&
        _scrollController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  Future<void> _loadCurrentFeed({bool refresh = false}) {
    return ref
        .read(feedProvider.notifier)
        .loadFeed(
          refresh: refresh,
          feedType: ref.read(feedTypeProvider),
          contentFilter: ref.read(feedContentFilterProvider),
        );
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
    _loadCurrentFeed(refresh: true);
  }

  void _onContentFilterChanged(FeedContentFilter filter) {
    ref.read(feedContentFilterProvider.notifier).set(filter);
    _loadCurrentFeed(refresh: true);
  }

  void _loadMore() {
    _loadCurrentFeed();
  }

  void _openComposer() {
    showBrutalistSheet(
      context: context,
      title: l10n(context).feedCreatePost,
      child: const CreateComposerSheet(),
    );
  }

  void _retry() {
    _loadCurrentFeed(refresh: ref.read(feedProvider).posts.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = l10n(context);
    ref.listen<FeedState>(feedProvider, (previous, next) {
      if (next.error != null &&
          next.posts.isNotEmpty &&
          previous?.error != next.error) {
        AppSnackbar.error(
          context,
          strings.feedRefreshFailedShowingPosts,
          action: SnackBarAction(label: strings.commonRetry, onPressed: _retry),
        );
      }
    });
    final feedState = ref.watch(feedProvider);
    final feedType = ref.watch(feedTypeProvider);
    final contentFilter = ref.watch(feedContentFilterProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: AppRefreshIndicator(
          onRefresh: () async {
            await _loadCurrentFeed(refresh: true);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Floating and snapping SliverAppBar to free all screen when scrolling
              const FeedHeader(),
              SliverToBoxAdapter(
                child: FeedIntroSections(
                  feedType: feedType,
                  contentFilter: contentFilter,
                  onFeedTypeChanged: _onFeedTypeChanged,
                  onContentFilterChanged: _onContentFilterChanged,
                  onCompose: _openComposer,
                ),
              ),
              FeedPostList(
                state: feedState,
                onRetry: _retry,
                emptyState: contentFilter == FeedContentFilter.all
                    ? EmptyState(
                        icon: Icons.article_outlined,
                        title: strings.feedNoPosts,
                        subtitle: strings.feedNoPostsBody,
                      )
                    : EmptyState(
                        icon: Icons.search_off,
                        title: strings.feedNoResults,
                        subtitle: strings.feedNoResultsBody,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
