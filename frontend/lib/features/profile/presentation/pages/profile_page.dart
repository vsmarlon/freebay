import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/guest_profile_view.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_header.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_settings_sheet.dart';

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
    final statsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'PERFIL',
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
          Expanded(
            child: profileAsync.when(
        data: (profileUser) {
          final u = profileUser;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statsAsync.when(
                  data: (stats) => ProfileHeader(
                    user: u,
                    followersCount: stats.followersCount,
                    followingCount: stats.followingCount,
                  ),
                  loading: () => ProfileHeader(user: u),
                  error: (_, __) => ProfileHeader(user: u),
                ),
                Spacing.vMd,
                Container(
                  width: double.infinity,
                  height: 1,
                  color: context.isDark
                      ? AppColors.outlineVariant.withAlpha(40)
                      : AppColors.surfaceContainerHigh,
                ),
                statsAsync.when(
                  data: (stats) => ProfileTabs(
                    user: u,
                    salesCount: stats.salesCount,
                    purchasesCount: stats.purchasesCount,
                  ),
                  loading: () => ProfileTabs(user: u),
                  error: (_, __) => ProfileTabs(user: u),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryContainer,
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                Spacing.vMd,
                Text(
                  'Erro ao carregar perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Spacing.vSm,
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
          ),
        ],
      ),
    );
  }
}
