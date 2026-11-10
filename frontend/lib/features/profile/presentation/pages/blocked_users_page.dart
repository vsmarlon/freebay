import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/profile/data/services/block_service.dart';
import 'package:freebay/features/profile/data/entities/block_responses.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
    final strings = l10n(context);
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.profileBlockedUsersTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
              breadcrumbs: context.breadcrumbs,
            ),
            Expanded(
              child: blockedUsersAsync.when(
                data: (response) {
                  return response.users.isEmpty
                      ? EmptyState(
                          icon: Icons.block_outlined,
                          title: strings.profileNoBlockedUsers,
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
                                onUnblock: () async {
                                  final service = ref.read(
                                    blockServiceProvider,
                                  );
                                  final result = await service.unblock(user.id);
                                  if (!context.mounted) return;
                                  result.fold(
                                    (failure) => AppSnackbar.handleFailure(
                                      context,
                                      failure,
                                    ),
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
                  message: strings.profileLoadFailed,
                  onRetry: () => ref.invalidate(blockedUsersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final BlockListUser user;
  final VoidCallback onUnblock;

  const _BlockedUserTile({required this.user, required this.onUnblock});

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
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: InkWell(
              onTap: onUnblock,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryContainer),
                ),
                child: Center(
                  child: Text(
                    l10n(context).profileUnblock,
                    style: const TextStyle(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
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
