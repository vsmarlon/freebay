import 'package:flutter/material.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_header.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_tabs.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final profileAsync = ref.watch(profileFutureProvider(userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'PERFIL',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: profileAsync.when(
                data: (profileUser) =>
                    _buildProfileContent(context, ref, isDark, profileUser),
                loading: () =>
                    const Center(child: ShimmerBlock(width: 60, height: 60)),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
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
                      Text(
                        'Não foi possível carregar as informações do usuário. Tente novamente.',
                        style: TextStyle(
                          color: isDark
                              ? context.textSecondary
                              : context.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserEntity user,
  ) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.value;
    final isOwnProfile = currentUser != null && currentUser.id == user.id;
    final followStatusAsync = !isOwnProfile
        ? ref.watch(followStatusProvider(user.id))
        : const AsyncValue<FollowStatusResponse?>.data(null);

    return LayoutBuilder(
      builder: (context, constraints) => InfiniteScrollListener(
        onLoadMore: () =>
            ref.read(profileTimelineProvider(user.id).notifier).loadMore(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              followStatusAsync.when(
                data: (status) => ProfileHeader(
                  user: user,
                  followersCount: status?.followersCount ?? user.followersCount,
                  followingCount: status?.followingCount ?? user.followingCount,
                ),
                loading: () => ProfileHeader(
                  user: user,
                  followersCount: user.followersCount,
                  followingCount: user.followingCount,
                ),
                error: (_, _) => ProfileHeader(
                  user: user,
                  followersCount: user.followersCount,
                  followingCount: user.followingCount,
                ),
              ),
              Spacing.vLg,
              if (!isOwnProfile && currentUser != null)
                followStatusAsync.when(
                  data: (status) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: (status?.isFollowing ?? false)
                            ? 'Seguindo'
                            : 'Seguir',
                        variant: (status?.isFollowing ?? false)
                            ? AppButtonVariant.ghost
                            : AppButtonVariant.primary,
                        onPressed: () async {
                          await ref
                              .read(followStateProvider.notifier)
                              .toggleFollow(
                                user.id,
                                fallbackFollowersCount: user.followersCount,
                                fallbackFollowingCount: user.followingCount,
                              );
                        },
                      ),
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ShimmerBlock(height: 48),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                )
              else if (!isOwnProfile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildFollowPrompt(context, isDark),
                ),
              if (user.reputationScore > 0)
                Center(
                  child: GestureDetector(
                    onTap: () => context.push(
                      '${AppRoutes.userReviewsPath(user.id)}?name=${Uri.encodeComponent(user.displayNameOrDefault)}',
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerDark
                            : AppColors.surfaceContainerHighest,
                        border: Border.all(
                          color: AppColors.onSurface.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          Spacing.hSm,
                          Text(
                            '${user.reputationScore.toStringAsFixed(1)} (${user.totalReviews} ${user.totalReviews == 1 ? 'avaliação' : 'avaliações'})',
                            style: TextStyle(
                              fontFamily: AppTypography.headlineFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.darkGray,
                            ),
                          ),
                          Spacing.hXs,
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Sem avaliações ainda',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? context.textSecondary
                            : context.textSecondary,
                      ),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                height: 1,
                margin: const EdgeInsets.only(bottom: 16),
                color: isDark
                    ? AppColors.outlineVariant.withAlpha(40)
                    : AppColors.surfaceContainerHigh,
              ),
              ProfileTabs(user: user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowPrompt(BuildContext context, bool isDark) {
    return Column(
      children: [
        Text(
          'Entre para seguir este usuário',
          style: TextStyle(color: context.textSecondary),
        ),
        Spacing.vMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => context.push(loginPathFrom(context)),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryContainer),
                ),
                child: const Center(
                  child: Text(
                    'Entrar',
                    style: TextStyle(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Cadastrar',
              onPressed: () => context.push(AppRoutes.register),
            ),
          ],
        ),
      ],
    );
  }
}
