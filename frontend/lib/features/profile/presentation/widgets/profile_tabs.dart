import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';

const _timelineKinds = <String>['posts', 'reposts', 'products'];
const _timelineLabels = <String>['PUBLICAÇÕES', 'REPOSTS', 'ANÚNCIOS'];

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
    return DefaultTabController(
      length: _timelineKinds.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          ...headerSlivers,
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileTabHeader(
              TabBar(
                tabs: [
                  for (final label in _timelineLabels)
                    Tab(
                      child: Semantics(
                        label: label,
                        button: true,
                        child: Text(label),
                      ),
                    ),
                ],
                labelColor: AppColors.primaryContainer,
                unselectedLabelColor: context.textSecondary,
                indicatorColor: AppColors.primaryContainer,
                indicatorWeight: 3,
                labelStyle: AppTypography.brutalistTag,
                unselectedLabelStyle: AppTypography.brutalistTag,
                dividerColor: Colors.transparent,
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            for (var index = 0; index < _timelineKinds.length; index++)
              _TimelineTab(
                key: ValueKey('${user.id}:${_timelineKinds[index]}'),
                user: user,
                kind: _timelineKinds[index],
                ownProfile:
                    ref.watch(authControllerProvider).value?.id == user.id,
              ),
          ],
        ),
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
    required this.ownProfile,
  });

  final UserEntity user;
  final String kind;
  final bool ownProfile;

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
    final provider = profileTimelineProvider(widget.user.id, kind: widget.kind);
    final timeline = ref.watch(provider);

    return InfiniteScrollListener(
      threshold: 500,
      onLoadMore: () => ref.read(provider.notifier).loadMore(),
      child: CustomScrollView(
        key: PageStorageKey('${widget.user.id}:${widget.kind}'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (timeline.entries.isEmpty && timeline.isLoading)
            const SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(child: ShimmerBlock(height: 160)),
            )
          else if (timeline.entries.isEmpty &&
              !timeline.hasMore &&
              timeline.error == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.article_outlined,
                title: widget.kind == 'products'
                    ? 'NENHUM ANÚNCIO'
                    : widget.kind == 'reposts'
                    ? 'NENHUM REPOST'
                    : 'NENHUMA PUBLICAÇÃO',
                subtitle: widget.kind == 'products'
                    ? 'Os anúncios deste perfil aparecerão aqui.'
                    : widget.kind == 'reposts'
                    ? 'Os reposts deste perfil aparecerão aqui.'
                    : 'As publicações deste perfil aparecerão aqui.',
                action: widget.ownProfile && widget.kind == 'posts'
                    ? AppButton(
                        label: 'Criar post',
                        onPressed: () => context.push(AppRoutes.createPost),
                      )
                    : null,
              ),
            )
          else if (timeline.entries.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
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
                child: Text(
                  'Carregando mais itens…',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
          if (timeline.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: 'Tentar novamente',
                  onPressed: () => ref.read(provider.notifier).loadMore(),
                ),
              ),
            ),
          if (timeline.isLoading && timeline.entries.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerBlock(height: 96),
              ),
            ),
        ],
      ),
    );
  }
}
