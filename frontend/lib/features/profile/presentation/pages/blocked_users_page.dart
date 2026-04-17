import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/features/profile/data/services/block_service.dart';

final blockServiceProvider = Provider<BlockService>((ref) {
  return BlockService();
});

final blockedUsersProvider = FutureProvider<BlockListResponse>((ref) async {
  final service = ref.watch(blockServiceProvider);
  final result = await service.getBlockedUsers();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (response) => response,
  );
});

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Usuários bloqueados',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
      body: blockedUsersAsync.when(
        data: (response) {
          if (response.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_outlined,
                    size: 64,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Você não bloqueou nenhum usuário',
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
            itemCount: response.users.length,
            itemBuilder: (context, index) {
              final user = response.users[index];
              return _BlockedUserTile(
                user: user,
                isDark: isDark,
                onUnblock: () async {
                  final service = ref.read(blockServiceProvider);
                  final result = await service.unblock(user.id);
                  result.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failure.message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
                    (_) {
                      ref.invalidate(blockedUsersProvider);
                    },
                  );
                },
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color:
                isDark ? AppColors.primaryPurpleLight : AppColors.primaryPurple,
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
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar usuários bloqueados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não foi possível carregar a lista. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => ref.invalidate(blockedUsersProvider),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      gradient: AppColors.brutalistGradient,
                    ),
                    child: const Center(
                      child: Text(
                        'Tentar novamente',
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
          ),
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final BlockListUser user;
  final bool isDark;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.user,
    required this.isDark,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user.avatarUrl,
            isVerified: user.isVerified,
            size: AppAvatarSize.medium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? AppColors.white : AppColors.darkGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: AppColors.primaryPurple,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.reputationScore.toStringAsFixed(1)} ★',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onUnblock,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryPurple),
              ),
              child: const Center(
                child: Text(
                  'Desbloquear',
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700,
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
