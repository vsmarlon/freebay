import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';

final followingProvider =
    FutureProvider.family<List<FollowerEntity>, String>((ref, userId) async {
  final repository = ProfileRepository();
  final result = await repository.getFollowing(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (following) => following,
  );
});

class FollowingPage extends ConsumerWidget {
  final String userId;

  const FollowingPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final followingAsync = ref.watch(followingProvider(userId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Seguindo'),
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
      body: followingAsync.when(
        data: (following) {
          if (following.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Não segue ninguém ainda',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: following.length,
            itemBuilder: (context, index) {
              final user = following[index];
              return _buildFollowingTile(context, user, isDark);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar seguindo',
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingTile(
      BuildContext context, FollowerEntity user, bool isDark) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => context.push('/user/${user.id}'),
        child: UserAvatar(
          imageUrl: user.avatarUrl,
          size: AppAvatarSize.medium,
          isVerified: user.isVerified,
        ),
      ),
      title: Text(
        user.displayName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.white : AppColors.darkGray,
        ),
      ),
      subtitle: user.bio != null && user.bio!.isNotEmpty
          ? Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            )
          : null,
      trailing: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          side: const BorderSide(color: AppColors.primaryPurple),
        ),
        child: const Text('Seguindo'),
      ),
    );
  }
}
