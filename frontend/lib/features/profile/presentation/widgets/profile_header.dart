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
import 'package:freebay/features/social/presentation/widgets/story_highlights_section.dart';

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
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.profileEdit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.borderSoftColor,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Editar perfil',
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),
                    ),
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
