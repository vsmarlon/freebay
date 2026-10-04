import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/data/entities/follow_responses.dart';
import 'package:freebay/features/profile/presentation/providers/follow_list_provider.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';

class FollowersPage extends ConsumerWidget {
  final String userId;

  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final followersAsync = ref.watch(followersListProvider(userId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.profileFollowersTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
              breadcrumbs: context.breadcrumbs,
            ),
            Expanded(
              child: followersAsync.when(
                data: (followers) {
                  if (followers.users.isEmpty) {
                    return EmptyState(
                      icon: Icons.people_outline,
                      title: strings.profileNoFollowers,
                      subtitle: strings.profileNoFollowersBody,
                    );
                  }
                  final currentUserId = ref
                      .watch(authControllerProvider)
                      .value
                      ?.id;
                  final users = List<UserBrief>.from(followers.users);
                  if (currentUserId != null) {
                    final selfIndex = users.indexWhere(
                      (user) => user.id == currentUserId,
                    );
                    if (selfIndex > 0) {
                      users.insert(0, users.removeAt(selfIndex));
                    }
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(followersListProvider(userId).notifier)
                        .loadMore(refresh: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200) {
                          ref
                              .read(followersListProvider(userId).notifier)
                              .loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isSelf = user.id == currentUserId;
                          final isFollowing =
                              ref
                                  .watch(followStateProvider)[user.id]
                                  ?.isFollowing ==
                              true;
                          return UserListTile(
                            user: UserListTileItem(
                              id: user.id,
                              displayName: user.displayName,
                              username: user.username ?? user.displayName,
                              avatarUrl: user.avatarUrl,
                            ),
                            trailing: isSelf
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    color: context.surfaceMidColor,
                                    child: Text(
                                      'VOCÊ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  )
                                : AppButton(
                                    label: isFollowing ? 'SEGUINDO' : 'SEGUIR',
                                    size: AppButtonSize.compact,
                                    variant: isFollowing
                                        ? AppButtonVariant.secondary
                                        : AppButtonVariant.primary,
                                    onPressed: () async {
                                      await ref
                                          .read(followStateProvider.notifier)
                                          .toggleFollow(user.id);
                                      await ref
                                          .read(
                                            followersListProvider(
                                              userId,
                                            ).notifier,
                                          )
                                          .loadMore(refresh: true);
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SkeletonPage(
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      ShimmerBlock(height: 60),
                      SizedBox(height: 12),
                      ShimmerBlock(height: 60),
                      SizedBox(height: 12),
                      ShimmerBlock(height: 60),
                    ],
                  ),
                ),
                error: (error, _) => EmptyState.error(
                  message: strings.errorUnknown,
                  onRetry: () => ref
                      .read(followersListProvider(userId).notifier)
                      .loadMore(refresh: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
