import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/guest_profile_view.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_header.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_settings_sheet.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/widgets/suggestions_section.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
    final suggestions = ref.read(suggestionsProvider);
    if (suggestions.users.isNotEmpty || suggestions.isLoading) return;

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
    final strings = l10n(context);

    // Auth still loading — show skeleton, not guest view
    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            ShellScrollHeader(child: PageHeader(text: strings.navProfile)),
            const Expanded(
              child: SkeletonPage(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    ShimmerBlock(height: 80, width: 80),
                    SizedBox(height: 12),
                    ShimmerBlock(height: 20, width: 160),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (authState.value == null) {
      return const GuestProfileView();
    }

    final userId = authState.value!.id;
    final profileAsync = ref.watch(profileFirstPaintProvider('me'));
    final statsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ShellScrollHeader(
            child: PageHeader(
              text: strings.navProfile,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.add_box_outlined,
                    color: context.textPrimary,
                  ),
                  tooltip: strings.feedCreatePost,
                  onPressed: () => context.push(AppRoutes.createPost),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: context.textPrimary,
                  ),
                  tooltip: strings.profileSettings,
                  onPressed: () => showProfileSettingsSheet(context),
                ),
                IconButton(
                  icon: Icon(
                    context.isDark ? Icons.light_mode : Icons.brightness_6,
                    color: context.textPrimary,
                  ),
                  tooltip: context.isDark
                      ? strings.profileSwitchToLight
                      : strings.profileSwitchToDark,
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: profileAsync.when(
              data: (firstPaint) {
                final u = firstPaint.user;
                return AppRefreshIndicator(
                  onRefresh: () async {
                    for (final kind in ['posts', 'reposts', 'products']) {
                      ref.invalidate(
                        profileTimelineProvider(
                          userId,
                          kind: kind,
                          viewerId: userId,
                        ),
                      );
                    }
                    await _refreshProfile();
                  },
                  child: ProfileTabs(
                    user: u,
                    headerSlivers: [
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
                      if (firstPaint.isStale)
                        SliverToBoxAdapter(
                          child: Semantics(
                            liveRegion: true,
                            child: Container(
                              color: context.surfaceMidColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md,
                                vertical: Spacing.sm,
                              ),
                              child: Text(
                                firstPaint.error == null
                                    ? l10n(context).profileCacheRefreshing
                                    : l10n(context).profileCacheRefreshFailed,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      const SuggestionsSection(),
                    ],
                  ),
                );
              },
              loading: () => const SkeletonPage(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    ShimmerBlock(height: 80, width: 80),
                    SizedBox(height: 12),
                    ShimmerBlock(height: 20, width: 160),
                    SizedBox(height: 6),
                    ShimmerBlock(height: 14, width: 100),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBlock(height: 20, width: 40),
                              SizedBox(height: 4),
                              ShimmerBlock(height: 12, width: 60),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBlock(height: 20, width: 40),
                              SizedBox(height: 4),
                              ShimmerBlock(height: 12, width: 60),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBlock(height: 20, width: 40),
                              SizedBox(height: 4),
                              ShimmerBlock(height: 12, width: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ShimmerBlock(height: 40),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 8),
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 8),
                        Expanded(child: ShimmerBlock(height: 120)),
                      ],
                    ),
                  ],
                ),
              ),
              error: (_, _) => EmptyState.error(
                message: l10n(context).profileLoadError,
                onRetry: _refreshProfile,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshProfile() async {
    final provider = profileFirstPaintProvider('me');
    final refreshed = Completer<void>();
    final subscription = ref.listenManual<AsyncValue<ProfileFirstPaint>>(
      provider,
      (_, next) {
        final data = next.asData?.value;
        if (next.hasError ||
            (data != null && (!data.isStale || data.error != null))) {
          if (!refreshed.isCompleted) refreshed.complete();
        }
      },
    );
    ref.invalidate(provider);
    try {
      await refreshed.future;
    } finally {
      subscription.close();
    }
  }
}
