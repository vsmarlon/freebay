import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';
import 'package:freebay/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            text: strings.notificationsTitle.toUpperCase(),
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              semanticLabel: strings.accessibilityBack,
              onTap: () => context.pop(),
            ),
            actions: [
              InkWell(
                onTap: () {
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                },
                child: Semantics(
                  button: true,
                  label: strings.notificationsMarkAllRead,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Icon(
                      Icons.done_all,
                      color: theme.brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () => SkeletonPage(
                child: SkeletonList(
                  itemCount: 6,
                  itemBuilder: (_, i) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBlock(width: 40, height: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBlock(height: 16, width: 180),
                              SizedBox(height: 6),
                              ShimmerBlock(height: 14),
                              SizedBox(height: 4),
                              ShimmerBlock(height: 12, width: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (error, _) => EmptyState.error(
                message: strings.notificationsLoadFailed,
                onRetry: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return EmptyState(
                    icon: Icons.notifications_none,
                    title: strings.notificationsNone,
                    subtitle: strings.notificationsEmptyBody,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                  child: InfiniteScrollListener(
                    onLoadMore: () =>
                        ref.read(notificationsProvider.notifier).loadMore(),
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationTile(notification: notification);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationEntity notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAgo = localizedTimeAgo(context, notification.createdAt);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        color: _getIconColor(notification.type),
        child: Icon(
          _getIcon(notification.type),
          color: AppColors.onPrimary,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          Spacing.vXs,
          Text(
            timeAgo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      onTap: () => _handleTap(context, ref),
      tileColor: notification.read
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (!notification.read) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    switch (notification.type) {
      case NotificationType.order:
        if (notification.orderId != null) {
          context.push(AppRoutes.orderPath(notification.orderId!));
        }
        break;
      case NotificationType.follow:
        if (notification.senderId != null) {
          context.push(AppRoutes.userPath(notification.senderId!));
        }
        break;
      case NotificationType.message:
        if (notification.conversationId != null) {
          context.push(AppRoutes.chatPath(notification.conversationId!));
        } else if (notification.orderId != null) {
          context.push(AppRoutes.chatPath(notification.orderId!));
        }
        break;
      case NotificationType.dispute:
        if (notification.orderId != null) {
          context.push(AppRoutes.orderPath(notification.orderId!));
        }
        break;
      case NotificationType.payment:
      case NotificationType.mention:
      case NotificationType.unknown:
        break;
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.dispute:
        return Icons.warning;
      case NotificationType.payment:
        return Icons.payments;
      case NotificationType.mention:
      case NotificationType.unknown:
        return Icons.notifications;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.success;
      case NotificationType.follow:
        return AppColors.info;
      case NotificationType.message:
        return AppColors.primaryContainer;
      case NotificationType.dispute:
        return AppColors.error;
      case NotificationType.payment:
        return AppColors.warning;
      case NotificationType.mention:
      case NotificationType.unknown:
        return AppColors.onSurfaceVariant;
    }
  }
}
