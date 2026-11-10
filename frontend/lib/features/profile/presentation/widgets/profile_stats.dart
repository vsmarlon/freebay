import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ProfileStats extends ConsumerWidget {
  const ProfileStats({
    super.key,
    required this.user,
    required this.followersCount,
    required this.followingCount,
  });

  final UserEntity user;
  final int followersCount;
  final int followingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final viewerId = ref.watch(
      authControllerProvider.select((auth) => auth.asData?.value?.id),
    );
    // `/users/me/stats` only describes the signed-in user; other profiles keep
    // the counts resolved by the follow-status provider.
    final stats = viewerId != null && viewerId == user.id
        ? ref.watch(profileStatsProvider).value
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        StatColumn(
          value: '${user.postsCount}',
          label: strings.profilePosts.toLowerCase(),
          size: 16,
          icon: Icons.article_outlined,
        ),
        StatColumn(
          value: '${stats?.followersCount ?? followersCount}',
          label: strings.profileFollowers.toLowerCase(),
          size: 16,
          icon: Icons.group_outlined,
          onTap: () => context.push(AppRoutes.followersWith(user.id)),
        ),
        StatColumn(
          value: '${stats?.followingCount ?? followingCount}',
          label: strings.profileFollowing.toLowerCase(),
          size: 16,
          icon: Icons.person_outline,
          onTap: () => context.push(AppRoutes.followingWith(user.id)),
        ),
      ],
    );
  }
}
