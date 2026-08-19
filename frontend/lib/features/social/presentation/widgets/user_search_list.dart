import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/infinite_scroll_listener.dart';

const _loadMoreThreshold = 200.0;

class UserSearchList extends StatelessWidget {
  final List<UserSearchEntity> users;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(String userId)? onFollow;
  final Function(String userId)? onUnfollow;
  final bool shrinkWrap;

  const UserSearchList({
    super.key,
    required this.users,
    this.isLoading = false,
    this.onLoadMore,
    this.onFollow,
    this.onUnfollow,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search,
              size: 64,
              color: AppColors.mediumGray,
            ),
            Spacing.vMd,
            const Text(
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
          return _UserSearchItem(
            user: user,
            onFollow: onFollow,
            onUnfollow: onUnfollow,
          );
        },
      ),
    );
  }
}

class _UserSearchItem extends ConsumerStatefulWidget {
  final UserSearchEntity user;
  final Function(String userId)? onFollow;
  final Function(String userId)? onUnfollow;

  const _UserSearchItem({required this.user, this.onFollow, this.onUnfollow});

  @override
  ConsumerState<_UserSearchItem> createState() => _UserSearchItemState();
}

class _UserSearchItemState extends ConsumerState<_UserSearchItem> {
  bool _isLoading = false;
  bool? _isFollowingOverride;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).value;
    final isOwnCard = currentUser != null && currentUser.id == widget.user.id;
    final followStatus = ref.watch(followStatusProvider(widget.user.id));
    final isFollowing =
        _isFollowingOverride ?? (followStatus.value?.isFollowing ?? false);

    return InkWell(
      onTap: () => context.push('/user/${widget.user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                image: widget.user.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.user.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: context.surfaceMidColor,
              ),
              child: widget.user.avatarUrl == null
                  ? Center(
                      child: Text(
                        widget.user.displayName[0].toUpperCase(),
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
                          widget.user.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.user.isVerified) ...[
                        Spacing.hXs,
                        const Icon(
                          Icons.verified,
                          color: AppColors.primaryContainer,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (widget.user.username != null &&
                      widget.user.username!.isNotEmpty)
                    Text(
                      '@${widget.user.username}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
                    Text(
                      widget.user.bio!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Spacing.vXs,
                  Text(
                    '${widget.user.followersCount} seguidores',
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
              followStatus.isLoading && _isFollowingOverride == null
                  ? const ShimmerBlock(width: 80, height: 32)
                  : AppButton(
                      label: isFollowing ? 'Seguindo' : 'Seguir',
                      variant: isFollowing
                          ? AppButtonVariant.ghost
                          : AppButtonVariant.primary,
                      size: AppButtonSize.compact,
                      isLoading: _isLoading,
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        if (isFollowing) {
                          await widget.onUnfollow?.call(widget.user.id);
                        } else {
                          await widget.onFollow?.call(widget.user.id);
                        }
                        ref.invalidate(followStatusProvider(widget.user.id));
                        setState(() {
                          _isFollowingOverride = !isFollowing;
                          _isLoading = false;
                        });
                      },
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
