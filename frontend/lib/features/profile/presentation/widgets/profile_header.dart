import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_banner.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_identity.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_media_actions.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_stats.dart';
import 'package:freebay/features/stories/stories.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ProfileHeader extends ConsumerWidget {
  final UserEntity user;
  final int followersCount;
  final int followingCount;

  const ProfileHeader({
    super.key,
    required this.user,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).value;
    final isOwnProfile = currentUser != null && currentUser.id == user.id;
    final effectiveFollowersCount = followersCount > 0
        ? followersCount
        : user.followersCount;
    final effectiveFollowingCount = followingCount > 0
        ? followingCount
        : user.followingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileBanner(
          user: user,
          isOwnProfile: isOwnProfile,
          onUpload: () => ProfileMediaActions.pickAndUploadBanner(context, ref),
          avatar: ProfileAvatar(user: user),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileIdentity(user: user),
              Spacing.vMd,
              ProfileStats(
                user: user,
                followersCount: effectiveFollowersCount,
                followingCount: effectiveFollowingCount,
              ),
              Spacing.vMd,
              if (isOwnProfile)
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: l10n(context).profileEdit,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(AppRoutes.profileEdit),
                  ),
                ),
              Spacing.vMd,
              StoryHighlightsSection(
                userId: user.id,
                isOwnProfile: isOwnProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
