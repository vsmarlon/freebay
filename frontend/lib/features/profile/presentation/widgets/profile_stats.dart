import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class ProfileStats extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StatColumn(value: '${user.postsCount}', label: 'posts', size: 18),
        StatColumn(
          value: '$followersCount',
          label: 'seguidores',
          size: 18,
          onTap: () => context.push(AppRoutes.followersWith(user.id)),
        ),
        StatColumn(
          value: '$followingCount',
          label: 'seguindo',
          size: 18,
          onTap: () => context.push(AppRoutes.followingWith(user.id)),
        ),
      ],
    );
  }
}
