import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/user_reposts_provider.dart';
import 'package:freebay/features/social/data/entities/user_post_entry.dart';

class ProfileTabs extends ConsumerStatefulWidget {
  final UserEntity user;

  const ProfileTabs({super.key, required this.user});

  @override
  ConsumerState<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends ConsumerState<ProfileTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final labels = const ['POSTS', 'REPOSTS'];
    return Column(
      children: [
        Row(
          children: List.generate(labels.length, (index) {
            final selected = _selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: Container(
                  color: selected ? context.surfaceColor : context.bgColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primaryContainer
                          : context.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        IndexedStack(
          index: _selectedIndex,
          children: [
            _PostsTab(userId: widget.user.id),
            _RepostsTab(userId: widget.user.id),
          ],
        ),
      ],
    );
  }
}

class _RepostsTab extends ConsumerWidget {
  final String userId;

  const _RepostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reposts = ref.watch(userRepostsProvider(userId));
    return reposts.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: ShimmerBlock(height: 120),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(32),
        child: Text('Não foi possível carregar os reposts: $error'),
      ),
      data: (entries) => entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Nenhum repost ainda'),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) =>
                  _RepostGridTile(entry: entries[index]),
            ),
    );
  }
}

class _RepostGridTile extends StatelessWidget {
  final UserPostEntry entry;

  const _RepostGridTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _PostGridTile(post: entry.toPostEntity()),
        const Positioned(
          right: 4,
          bottom: 4,
          child: Icon(Icons.repeat, color: AppColors.onPrimary, size: 18),
        ),
      ],
    );
  }
}

class _PostsTab extends ConsumerWidget {
  final String userId;

  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userPostsProvider(userId));
    final notifier = ref.read(userPostsProvider(userId).notifier);

    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.value;
    final isOwnProfile = currentUser != null && currentUser.id == userId;

    if (state.isLoading && state.posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: GridView(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            ShimmerBlock(height: 120),
            ShimmerBlock(height: 120),
            ShimmerBlock(height: 120),
            ShimmerBlock(height: 120),
            ShimmerBlock(height: 120),
            ShimmerBlock(height: 120),
          ],
        ),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: AppColors.mediumGray.withAlpha(100),
              ),
              Spacing.vMd,
              Text(
                'Nenhum post ainda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              if (isOwnProfile) ...[
                Spacing.vSm,
                const Text(
                  'Compartilhe momentos no seu perfil',
                  style: TextStyle(fontSize: 14, color: AppColors.mediumGray),
                ),
                Spacing.vLg,
                AppButton(
                  label: 'Criar post',
                  size: AppButtonSize.compact,
                  onPressed: () => context.push(AppRoutes.createStory),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return InfiniteScrollListener(
      onLoadMore: notifier.loadMore,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: state.posts.length,
        itemBuilder: (context, index) {
          final post = state.posts[index];
          return _PostGridTile(post: post);
        },
      ),
    );
  }
}

class _PostGridTile extends StatelessWidget {
  final PostEntity post;

  const _PostGridTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.postPath(post.id)),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.surfaceContainer),
        child: post.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: post.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.photo, color: AppColors.mediumGray, size: 24),
    );
  }
}
