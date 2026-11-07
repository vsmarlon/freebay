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
      child: TabBarView(
        children: [
          for (final kind in _timelineKinds)
            _TimelineTab(
              key: ValueKey('${user.id}:$kind:${viewerId ?? 'anonymous'}'),
              user: user,
              kind: kind,
              viewerId: viewerId,
              labels: labels,
              headerSlivers: headerSlivers,
            ),
        ],
      ),
    );
  }
}

class _ProfileTabHeader extends SliverPersistentHeaderDelegate {
  const _ProfileTabHeader(this.tabBar);

  final TabBar tabBar;

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
    required this.labels,
    required this.headerSlivers,
  });

  final UserEntity user;
  final String kind;
  final String? viewerId;
  final List<String> labels;
  final List<Widget> headerSlivers;

  @override
  ConsumerState<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends ConsumerState<_TimelineTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...widget.headerSlivers,
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileTabHeader(
              TabBar(
                tabs: [
                  for (final label in widget.labels)
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
              ),
            ),
          ),
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
