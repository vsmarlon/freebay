import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';

class NewChatUserTile extends StatelessWidget {
  final UserSearchEntity user;
  final VoidCallback onTap;

  const NewChatUserTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          image: user.avatarUrl != null
              ? DecorationImage(
                  image: NetworkImage(user.avatarUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: context.surfaceColor,
        ),
        child: user.avatarUrl == null
            ? Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                ),
              )
            : null,
      ),
      title: Row(
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
      subtitle: user.followersCount > 0
          ? Text(
              '${user.followersCount} seguidores',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            )
          : null,
      onTap: onTap,
    );
  }
}
