import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_refresh_indicator.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/guest_profile_view.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_header.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_settings_sheet.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/widgets/suggestions_section.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(suggestionsProvider.notifier).loadSuggestions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authControllerProvider);

    if (authState.value == null) {
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
                icon: Icon(Icons.settings_outlined, color: context.textPrimary),
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
                return AppRefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(profileFutureProvider('me').future),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverToBoxAdapter(
                          child: statsAsync.when(
                            data: (stats) => ProfileHeader(
                              user: u,
                              followersCount: stats.followersCount,
                              followingCount: stats.followingCount,
                            ),
                            loading: () => ProfileHeader(user: u),
                            error: (_, _) => ProfileHeader(user: u),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            height: 1,
                            color: context.isDark
                                ? AppColors.outlineVariant.withAlpha(40)
                                : AppColors.surfaceContainerHigh,
                          ),
                        ),
                      ),
                      const SuggestionsSection(),
                      SliverToBoxAdapter(child: ProfileTabs(user: u)),
                    ],
                  ),
                );
              },
              loading: () => SkeletonPage(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const ShimmerBlock(height: 80, width: 80),
                    const SizedBox(height: 12),
                    const ShimmerBlock(height: 20, width: 160),
                    const SizedBox(height: 6),
                    const ShimmerBlock(height: 14, width: 100),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ShimmerBlock(height: 20, width: 40),
                              const SizedBox(height: 4),
                              const ShimmerBlock(height: 12, width: 60),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ShimmerBlock(height: 20, width: 40),
                              const SizedBox(height: 4),
                              const ShimmerBlock(height: 12, width: 60),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ShimmerBlock(height: 20, width: 40),
                              const SizedBox(height: 4),
                              const ShimmerBlock(height: 12, width: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const ShimmerBlock(height: 40),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: ShimmerBlock(height: 120)),
                        const SizedBox(width: 8),
                        Expanded(child: ShimmerBlock(height: 120)),
                        const SizedBox(width: 8),
                        Expanded(child: ShimmerBlock(height: 120)),
                      ],
                    ),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
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
