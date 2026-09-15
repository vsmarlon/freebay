import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/router/app_routes.dart';

class UserListTileItem {
  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? bio;

  const UserListTileItem({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.bio,
  });
}

class UserListTile extends StatelessWidget {
  final UserListTileItem user;
  final Widget? trailing;

  const UserListTile({super.key, required this.user, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.userPath(user.id)),
        child: Row(
          children: [
            UserAvatar(imageUrl: user.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
