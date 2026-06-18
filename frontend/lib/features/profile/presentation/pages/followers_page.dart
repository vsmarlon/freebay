import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/data/entities/follower_entity.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/page_header.dart';

final followersProvider =
    FutureProvider.family<List<FollowerEntity>, String>((ref, userId) async {
  final repository = ProfileRepository();
  final result = await repository.getFollowers(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (followers) => followers,
  );
});

class FollowersPage extends ConsumerWidget {
  final String userId;

  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final followersAsync = ref.watch(followersProvider(userId));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'SEGUIDORES',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
            breadcrumbs: [
              BreadcrumbItem(label: 'Perfil', onTap: () => context.pop()),
              const BreadcrumbItem(label: 'Seguidores'),
            ],
          ),
          Expanded(
            child: followersAsync.when(
              data: (followers) {
                return followers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: isDark
                                  ? AppColors.mediumGray
                                  : AppColors.mediumGray,
                            ),
                            Spacing.vMd,
                            Text(
                              'Nenhum seguidor ainda',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? AppColors.mediumGray
                                    : AppColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(followersProvider(userId));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: followers.length,
                          itemBuilder: (context, index) {
                            final follower = followers[index];
                            return _buildFollowerTile(
                                context, ref, follower, isDark);
                          },
                        ),
                      );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryContainer),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    Spacing.vMd,
                    Text(
                      'Erro ao carregar seguidores',
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerTile(BuildContext context, WidgetRef ref,
      FollowerEntity follower, bool isDark) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => context.push('/user/${follower.id}'),
        child: UserAvatar(
          imageUrl: follower.avatarUrl,
          size: AppAvatarSize.medium,
          isVerified: follower.isVerified,
        ),
      ),
      title: Text(
        follower.displayName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.white : AppColors.darkGray,
        ),
      ),
      subtitle: follower.bio != null && follower.bio!.isNotEmpty
          ? Text(
              follower.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            )
          : null,
      trailing: follower.isFollowing
          ? InkWell(
              onTap: () {},
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryContainer),
                ),
                child: const Center(
                  child: Text(
                    'Seguindo',
                    style: TextStyle(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          : InkWell(
              onTap: () {},
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: AppColors.brutalistGradient,
                ),
                child: const Center(
                  child: Text(
                    'Seguir',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
