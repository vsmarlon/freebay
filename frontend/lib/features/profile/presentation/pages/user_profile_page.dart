import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/components/reputation_stars.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

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
        data: (user) => _buildProfileContent(context, isDark, user),
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
      BuildContext context, bool isDark, UserEntity user) {
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
            user.displayName,
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
            ReputationStars(score: user.reputationScore.toDouble()),
          const SizedBox(height: 24),
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
          Text(
            'Reputação: ${user.reputationScore.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
