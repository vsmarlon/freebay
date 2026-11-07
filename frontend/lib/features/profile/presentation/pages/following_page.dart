import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/providers/follow_list_provider.dart';
import 'package:freebay/features/profile/presentation/providers/follow_status_provider.dart';

class FollowingPage extends ConsumerWidget {
  final String userId;

  const FollowingPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final followingAsync = ref.watch(followingListProvider(userId));
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    // Own following list means the edge exists until the follow provider says
    // otherwise; someone else's list says nothing about the viewer.
    final defaultFollowed =
        currentUserId != null && (userId == 'me' || userId == currentUserId);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.profileFollowingTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
              breadcrumbs: context.breadcrumbs,
            ),
            Expanded(
              child: followingAsync.when(
                data: (following) => following.users.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: strings.profileNoConnections,
                        subtitle: strings.profileNoFollowingBody,
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(followingListProvider(userId).notifier)
                            .loadMore(refresh: true),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.pixels >=
                                notification.metrics.maxScrollExtent - 200) {
                              ref
                                  .read(followingListProvider(userId).notifier)
                                  .loadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: following.users.length,
                            itemBuilder: (context, index) {
                              final user = following.users[index];
                              final isFollowing =
                                  ref
                                      .watch(followStateProvider)[user.id]
                                      ?.isFollowing ??
                                  defaultFollowed;
                              return UserListTile(
                                user: UserListTileItem(
                                  id: user.id,
                                  displayName: user.displayName,
                                  username: user.username ?? user.displayName,
                                  avatarUrl: user.avatarUrl,
                                ),
                                trailing: AppButton(
                                  label:
                                      (isFollowing
                                              ? strings.profileUnfollow
                                              : strings.profileFollow)
                                          .toUpperCase(),
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
                                          followingListProvider(
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
                      ),
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
                      .read(followingListProvider(userId).notifier)
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
