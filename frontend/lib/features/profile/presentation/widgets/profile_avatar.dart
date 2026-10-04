import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_media_actions.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).value;
    final isOwnProfile = currentUser != null && currentUser.id == user.id;
    Widget avatar = GestureDetector(
      onTap: isOwnProfile ? () => _showAvatarOptions(context, ref) : null,
      child: UserAvatar(
        imageUrl: user.avatarUrl,
        blurHash: user.avatarBlurHash,
        isVerified: user.isVerified,
        size: AppAvatarSize.large,
        heroTag: 'profile-avatar-${user.id}',
      ),
    );
    if (user.hasActiveStory) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(gradient: AppColors.brutalistGradient),
        child: avatar,
      );
    }
    return avatar;
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showBrutalistSheet(
      context: context,
      title: l10n(context).profilePhoto,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const _AvatarActionIcon(icon: Icons.camera_alt),
            title: Text(l10n(context).profileChangePhoto),
            onTap: () {
              Navigator.pop(sheetContext);
              ProfileMediaActions.pickAndUploadAvatar(context, ref);
            },
          ),
          ListTile(
            leading: const _AvatarActionIcon(icon: Icons.add),
            title: Text(l10n(context).feedCreateStory),
            subtitle: Text(
              l10n(context).profileStorySharePrompt,
              style: TextStyle(color: context.textSecondary),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              context.push(AppRoutes.createStory);
            },
          ),
          if (user.hasActiveStory)
            ListTile(
              leading: const _AvatarActionIcon(
                icon: Icons.auto_awesome,
                highlighted: true,
              ),
              title: Text(l10n(context).profileOpenMyStories),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.profileStories);
              },
            ),
          Spacing.vMd,
        ],
      ),
    );
  }
}

class _AvatarActionIcon extends StatelessWidget {
  const _AvatarActionIcon({required this.icon, this.highlighted = false});

  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: highlighted ? null : AppColors.brutalistGradient,
        color: highlighted ? AppColors.surfaceContainerHighest : null,
      ),
      child: Icon(
        icon,
        color: highlighted ? AppColors.primaryContainer : AppColors.white,
      ),
    );
  }
}
