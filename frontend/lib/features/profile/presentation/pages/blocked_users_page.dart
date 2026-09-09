import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/profile/data/services/block_service.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';
import 'package:freebay/core/router/navigation_tracker.dart';

final blockServiceProvider = Provider<BlockService>((ref) {
  return BlockService();
});

final blockedUsersProvider = FutureProvider<BlockListResponse>((ref) async {
  final service = ref.watch(blockServiceProvider);
  final result = await service.getBlockedUsers();
  return result.fold((failure) => throw failure, (response) => response);
});

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'USUÁRIOS BLOQUEADOS',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            breadcrumbs: context.breadcrumbs,
          ),
          Expanded(
            child: blockedUsersAsync.when(
              data: (response) {
                return response.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block_outlined,
                              size: 64,
                              color: isDark
                                  ? AppColors.mediumGray
                                  : AppColors.mediumGray,
                            ),
                            Spacing.vMd,
                            Text(
                              'Você não bloqueou nenhum usuário',
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
                          ref.invalidate(blockedUsersProvider);
                        },
                        child: ListView.builder(
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
                        ),
                      );
              },
              loading: () =>
                  const Center(child: ShimmerBlock(width: 20, height: 20)),
              error: (err, stack) => EmptyState.error(
                message:
                    'Não foi possível carregar a lista. Verifique sua conexão.',
                onRetry: () => ref.invalidate(blockedUsersProvider),
              ),
            ),
          ),
        ],
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
          UserAvatar(imageUrl: user.avatarUrl, isVerified: user.isVerified),
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
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      Spacing.hXs,
                      const Icon(
                        Icons.verified,
                        color: AppColors.primaryContainer,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.reputationScore.toStringAsFixed(1)} ★',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
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
                border: Border.all(color: AppColors.primaryContainer),
              ),
              child: const Center(
                child: Text(
                  'Desbloquear',
                  style: TextStyle(
                    color: AppColors.primaryContainer,
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
