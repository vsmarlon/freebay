import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class ProfileTabs extends ConsumerWidget {
  final UserEntity user;

  const ProfileTabs({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PostsTab(userId: user.id);
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
                  onPressed: () => context.push('/create-story'),
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
      onTap: () => context.push('/post/${post.id}'),
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
