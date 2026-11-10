import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/features/social/social.dart' show FeedPostItem;
import 'package:freebay/shared/l10n/app_localizations_context.dart';

const _timelineKinds = <String>['posts', 'reposts', 'products'];

/// Notifications that may complete the profile's pull-to-refresh.
///
/// The inner timelines report at depth 1 and the collapsing header at depth 0,
/// so both are accepted; the trigger itself is pointer-driven via
/// [ProfileRefresh]. Ballistic notifications that merely cross the top from a
/// scroll started below must not re-arm the indicator: [RefreshIndicator]
/// armed by any [OverscrollNotification] makes every fling to the top spin.
bool _isProfileRefreshNotification(ScrollNotification notification) =>
    notification.metrics.axis == Axis.vertical && notification.depth <= 2;

/// Pull-to-refresh for the profile tabs.
///
/// [RefreshIndicator] only arms after a pull proportional to the scroll
/// viewport (25% of it). The profile header fills most of that viewport, so a
/// pull started on the visible timeline cannot reach the threshold. This keeps
/// the same indicator and also arms it from pointer travel when the gesture
/// starts at the top.
class ProfileRefresh extends StatefulWidget {
  const ProfileRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<ProfileRefresh> createState() => _ProfileRefreshState();
}

class _ProfileRefreshState extends State<ProfileRefresh> {
  static const double _pullThreshold = 80;

  final GlobalKey<RefreshIndicatorState> _indicator =
      GlobalKey<RefreshIndicatorState>();
  bool _atTop = true;
  bool _startedAtTop = false;
  bool _triggered = false;
  double _startX = 0;
  double _startY = 0;

  bool _handleScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis == Axis.vertical) {
      // Depth 0 is the collapsing header; it only ever sits at min while the
      // timelines are at top too, so it alone decides "at top".
      if (notification.depth == 0 && metrics.hasContentDimensions) {
        _atTop = metrics.pixels <= metrics.minScrollExtent;
      }
    }
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _startX = event.position.dx;
    _startY = event.position.dy;
    _startedAtTop = _atTop;
    _triggered = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_triggered || !_startedAtTop) return;
    final dy = event.position.dy - _startY;
    if (dy < _pullThreshold || dy < (event.position.dx - _startX).abs()) {
      return;
    }
    _triggered = true;
    _indicator.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _indicator,
      color: AppColors.primaryContainer,
      notificationPredicate: (notification) =>
          // Own and ballistic scroll-end notifications may complete a show();
          // drags must not arm the indicator itself (the Listener above does).
          notification is! ScrollUpdateNotification &&
          _isProfileRefreshNotification(notification),
      onRefresh: widget.onRefresh,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScroll,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Refreshes posts, reposts and products, keeping each timeline alive while it
/// loads. Without the listeners, auto-dispose cancels the request of a tab that
/// is not currently built (only the visible and adjacent tabs exist).
Future<void> refreshProfileTimelines(WidgetRef ref, String userId) async {
  final viewerId = ref.read(authControllerProvider).asData?.value?.id;
  final providers = [
    for (final kind in _timelineKinds)
      profileTimelineProvider(userId, kind: kind, viewerId: viewerId),
  ];
  final subscriptions = [
    for (final provider in providers)
      ref.listenManual<ProfileTimelineState>(provider, (_, _) {}),
  ];
  try {
    await Future.wait([
      for (final provider in providers) ref.read(provider.notifier).refresh(),
    ]);
  } finally {
    for (final subscription in subscriptions) {
      subscription.close();
    }
  }
}

class ProfileTabs extends ConsumerWidget {
  const ProfileTabs({
    super.key,
    required this.user,
    this.headerSlivers = const [],
  });

  final UserEntity user;
  final List<Widget> headerSlivers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final viewerId = ref.watch(
      authControllerProvider.select((auth) => auth.asData?.value?.id),
    );
    final labels = [
      strings.profilePosts,
      strings.profileRepostsTab,
      strings.profileListingsTab,
    ];
    return DefaultTabController(
      length: _timelineKinds.length,
      child: NestedScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          ...headerSlivers,
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileTabHeader(_ProfileTabBar(labels: labels)),
          ),
        ],
        body: TabBarView(
          children: [
            for (final kind in _timelineKinds)
              _TimelineTab(
                key: ValueKey('${user.id}:$kind:${viewerId ?? 'anonymous'}'),
                user: user,
                kind: kind,
                viewerId: viewerId,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: [
        for (final label in labels)
          Tab(
            child: Semantics(
              label: label,
              button: true,
              child: Text(label.toUpperCase()),
            ),
          ),
      ],
      labelColor: context.colors.primary,
      unselectedLabelColor: context.textSecondary,
      indicatorColor: AppColors.primaryContainer,
      indicatorWeight: 3,
      labelStyle: AppTypography.brutalistTag,
      unselectedLabelStyle: AppTypography.brutalistTag,
      dividerColor: Colors.transparent,
    );
  }
}

class _ProfileTabHeader extends SliverPersistentHeaderDelegate {
  const _ProfileTabHeader(this.tabBar);

  final Widget tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: context.bgColor, child: tabBar);

  @override
  bool shouldRebuild(_ProfileTabHeader oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _TimelineTab extends ConsumerStatefulWidget {
  const _TimelineTab({
    super.key,
    required this.user,
    required this.kind,
    required this.viewerId,
  });

  final UserEntity user;
  final String kind;
  final String? viewerId;

  @override
  ConsumerState<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends ConsumerState<_TimelineTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = profileTimelineProvider(
      widget.user.id,
      kind: widget.kind,
      viewerId: widget.viewerId,
    );
    final timeline = ref.watch(provider);
    final strings = l10n(context);

    return InfiniteScrollListener(
      threshold: 500,
      onLoadMore: () {
        if (timeline.error == null) ref.read(provider.notifier).loadMore();
      },
      child: CustomScrollView(
        key: PageStorageKey('${widget.user.id}:${widget.kind}'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (timeline.entries.isEmpty && timeline.isLoading)
            const SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: ShimmerScope(child: ShimmerBlock(height: 160)),
              ),
            )
          else if (timeline.entries.isEmpty && timeline.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState.error(
                message: strings.profileLoadFailed,
                onRetry: () => ref.read(provider.notifier).loadMore(),
              ),
            )
          else if (timeline.entries.isEmpty && !timeline.hasMore)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.article_outlined,
                title: switch (widget.kind) {
                  'reposts' => strings.profileNoReposts,
                  'products' => strings.productNoListings,
                  _ => strings.profileNoPosts,
                },
                subtitle: switch (widget.kind) {
                  'reposts' => strings.profileNoRepostsBody,
                  'products' => strings.productListingsEmpty,
                  _ => strings.profileNoPostsBody,
                },
                action:
                    widget.viewerId == widget.user.id && widget.kind == 'posts'
                    ? AppButton(
                        label: strings.feedCreatePost,
                        onPressed: () => context.push(AppRoutes.createPost),
                      )
                    : widget.viewerId == widget.user.id &&
                          widget.kind == 'products'
                    ? AppButton(
                        label: strings.productCreateListing,
                        onPressed: () => context.push(AppRoutes.createProduct),
                      )
                    : null,
              ),
            )
          else if (timeline.entries.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.sm,
                Spacing.md,
                Spacing.md,
              ),
              sliver: SliverList.builder(
                itemCount: timeline.entries.length,
                itemBuilder: (context, index) {
                  final entry = timeline.entries[index];
                  return FeedPostItem(
                    key: ValueKey(entry.repostId ?? entry.post.id),
                    post: entry.toPostEntity(),
                  );
                },
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppButton(
                  label: strings.profileLoadMore,
                  onPressed: () => ref.read(provider.notifier).loadMore(),
                ),
              ),
            ),
          if (timeline.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(strings.profileLoadFailed),
                    Spacing.vSm,
                    AppButton(
                      label: strings.commonRetry,
                      onPressed: () => ref.read(provider.notifier).loadMore(),
                    ),
                  ],
                ),
              ),
            ),
          if (timeline.isLoading && timeline.entries.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerScope(child: ShimmerBlock(height: 96)),
              ),
            ),
        ],
      ),
    );
  }
}
