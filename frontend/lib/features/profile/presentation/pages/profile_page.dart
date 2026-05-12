import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/guest_profile_view.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_menu_list.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_settings_sheet.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_stats_section.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_stories_sheet.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isGuest = authState.valueOrNull?.isGuest ?? false;

    if (isGuest) {
      return const GuestProfileView();
    }

    final profileAsync = ref.watch(profileFutureProvider('me'));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.appBarColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: context.textPrimary,
            ),
            onPressed: () => showProfileSettingsSheet(context),
          ),
          IconButton(
            icon: Icon(
              context.isDark ? Icons.light_mode : Icons.brightness_6,
              color: context.textPrimary,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => showProfileStoriesSheet(context),
                  child: Stack(
                    children: [
                      UserAvatar(
                        imageUrl: user.avatarUrl,
                        isVerified: user.isVerified,
                        size: AppAvatarSize.large,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayNameOrDefault,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                if (user.city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.city!,
                        style: const TextStyle(
                          color: AppColors.mediumGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (user.bio != null)
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 32),
                const ProfileStatsRow(),
                const SizedBox(height: 16),
                const ProfileFollowRow(),
                const SizedBox(height: 32),
                const ProfileMenuList(),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
              color: AppColors.primaryPurple),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Não foi possível carregar suas informações. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mediumGray),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
