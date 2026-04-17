import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/components/reputation_stars.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/data/services/follow_service.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

final followServiceProvider = Provider<FollowService>((ref) => FollowService());

final followStatusProvider =
    FutureProvider.family<FollowStatusResponse?, String>((ref, userId) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.valueOrNull;

  if (user == null || user.isGuest) {
    return null;
  }

  final service = ref.watch(followServiceProvider);
  final result = await service.getFollowStatus(userId);

  return result.fold(
    (failure) => null,
    (status) => status,
  );
});

class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileFutureProvider(userId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        data: (user) => _buildProfileContent(context, ref, isDark, user),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Não foi possível carregar as informações do usuário. Tente novamente.',
                style: TextStyle(
                  color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context, WidgetRef ref, bool isDark, UserEntity user) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.valueOrNull;
    final isOwnProfile = currentUser != null &&
        !currentUser.isGuest &&
        currentUser.id == user.id;
    final followStatusAsync = !isOwnProfile
        ? ref.watch(followStatusProvider(user.id))
        : const AsyncValue<FollowStatusResponse?>.data(null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          UserAvatar(
            imageUrl: user.avatarUrl,
            size: AppAvatarSize.large,
            isVerified: user.isVerified,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayNameOrDefault,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              user.bio!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          if (user.reputationScore > 0)
            GestureDetector(
              onTap: () => context.push(
                '/user/${user.id}/reviews?name=${Uri.encodeComponent(user.displayNameOrDefault)}',
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ReputationStars(
                    score: user.reputationScore.toDouble(),
                    reviewCount: user.totalReviews,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                ],
              ),
            ),
          if (user.reputationScore <= 0 && user.totalReviews == 0)
            Text(
              'Sem avaliações',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            ),
          const SizedBox(height: 24),
          if (!isOwnProfile && currentUser != null && !currentUser.isGuest)
            followStatusAsync.when(
              data: (status) =>
                  _buildFollowButton(context, ref, user.id, isDark, status),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) =>
                  _buildFollowButton(context, ref, user.id, isDark, null),
            )
          else if (!isOwnProfile)
            _buildFollowPrompt(context, isDark),
          const SizedBox(height: 16),
          if (user.city != null && user.city!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                ),
                const SizedBox(width: 4),
                Text(
                  user.city!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (user.totalReviews > 0)
            GestureDetector(
              onTap: () => context.push(
                '/user/${user.id}/reviews?name=${Uri.encodeComponent(user.displayNameOrDefault)}',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerHighest,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${user.reputationScore.toStringAsFixed(1)} (${user.totalReviews} ${user.totalReviews == 1 ? 'avaliação' : 'avaliações'})',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.outline,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              'Sem avaliações ainda',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, WidgetRef ref, String userId,
      bool isDark, FollowStatusResponse? status) {
    final isFollowing = status?.isFollowing ?? false;
    final followersCount = status?.followersCount ?? 0;
    final followingCount = status?.followingCount ?? 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatChip('Seguidores', followersCount, isDark),
            const SizedBox(width: 24),
            _buildStatChip('Seguindo', followingCount, isDark),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: () async {
              final service = ref.read(followServiceProvider);
              final result = isFollowing
                  ? await service.unfollow(userId)
                  : await service.follow(userId);

              if (result.isRight()) {
                ref.invalidate(followStatusProvider(userId));
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: isFollowing ? null : AppColors.brutalistGradient,
                color: isFollowing
                    ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                    : null,
                border: isFollowing
                    ? Border.all(color: AppColors.primaryPurple)
                    : null,
              ),
              child: Center(
                child: Text(
                  isFollowing ? 'Seguindo' : 'Seguir',
                  style: TextStyle(
                    color: isFollowing ? AppColors.primaryPurple : AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.zero,
        ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowPrompt(BuildContext context, bool isDark) {
    return Column(
      children: [
        Text(
          'Entre para seguir este usuário',
          style: TextStyle(
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => context.push('/login'),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryPurple),
                ),
                child: const Center(
                  child: Text(
                    'Entrar',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => context.push('/register'),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  gradient: AppColors.brutalistGradient,
                ),
                child: const Center(
                  child: Text(
                    'Cadastrar',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
