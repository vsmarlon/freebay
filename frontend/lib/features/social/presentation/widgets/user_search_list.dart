import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';

const _loadMoreThreshold = 200.0;

class UserSearchList extends StatelessWidget {
  final List<UserSearchEntity> users;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final bool shrinkWrap;

  const UserSearchList({
    super.key,
    required this.users,
    this.isLoading = false,
    this.onLoadMore,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty && !isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: AppColors.mediumGray),
            Spacing.vMd,
            Text(
              'Nenhum usuário encontrado',
              style: TextStyle(color: AppColors.mediumGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return InfiniteScrollListener(
      threshold: _loadMoreThreshold,
      onLoadMore: () => onLoadMore?.call(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        itemCount: users.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerBlock(height: 72),
            );
          }

          final user = users[index];
          return _UserSearchItem(user: user);
        },
      ),
    );
  }
}

class _UserSearchItem extends ConsumerWidget {
  final UserSearchEntity user;

  const _UserSearchItem({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).value;
    final isOwnCard = currentUser != null && currentUser.id == user.id;
    final followStatus = ref.watch(followStatusProvider(user.id));
    final isFollowing = followStatus.value?.isFollowing ?? false;
    final isBusy = ref.watch(followsInFlightProvider).contains(user.id);

    return InkWell(
      onTap: () => context.push(AppRoutes.userPath(user.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                image: user.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: context.surfaceMidColor,
              ),
              child: user.avatarUrl == null
                  ? Center(
                      child: Text(
                        user.displayName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        Spacing.hXs,
                        const Icon(
                          Icons.verified,
                          color: AppColors.primaryContainer,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (user.username != null && user.username!.isNotEmpty)
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Text(
                      user.bio!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Spacing.vXs,
                  Text(
                    '${user.followersCount} seguidores',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            if (!isOwnCard) ...[
              Spacing.hSm,
              followStatus.isLoading &&
                      !ref.watch(followStateProvider).containsKey(user.id)
                  ? const ShimmerBlock(width: 80, height: 32)
                  : AppButton(
                      label: isFollowing ? 'Seguindo' : 'Seguir',
                      variant: isFollowing
                          ? AppButtonVariant.ghost
                          : AppButtonVariant.primary,
                      size: AppButtonSize.compact,
                      isLoading: isBusy,
                      onPressed: () => ref
                          .read(followStateProvider.notifier)
                          .toggleFollow(
                            user.id,
                            fallbackFollowersCount: user.followersCount,
                            fallbackFollowingCount: user.followingCount,
                          ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
