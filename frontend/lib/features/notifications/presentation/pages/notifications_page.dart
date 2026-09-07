import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/time_utils.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';
import 'package:freebay/features/notifications/presentation/providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            text: 'NOTIFICAÇÕES',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            actions: [
              InkWell(
                onTap: () {
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                },
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
                message:
                    'Não foi possível carregar suas notificações. Puxe para atualizar ou tente novamente em instantes.',
                onRetry: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_none,
                    title: 'NENHUMA NOTIFICAÇÃO',
                    subtitle:
                        'Você será notificado sobre pedidos, mensagens e muito mais.',
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
    final timeAgo = TimeUtils.timeAgo(notification.createdAt);

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
      case 'ORDER':
        if (notification.orderId != null) {
          context.push('/orders/${notification.orderId}');
        }
        break;
      case 'FOLLOW':
        if (notification.senderId != null) {
          context.push('/user/${notification.senderId}');
        }
        break;
      case 'MESSAGE':
        if (notification.conversationId != null) {
          context.push('/chat/${notification.conversationId}');
        } else if (notification.orderId != null) {
          context.push('/chat/${notification.orderId}');
        }
        break;
      case 'DISPUTE':
        if (notification.orderId != null) {
          context.push('/orders/${notification.orderId}');
        }
        break;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'ORDER':
        return Icons.shopping_bag;
      case 'FOLLOW':
        return Icons.person_add;
      case 'MESSAGE':
        return Icons.chat_bubble;
      case 'DISPUTE':
        return Icons.warning;
      case 'PAYMENT':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'ORDER':
        return AppColors.success;
      case 'FOLLOW':
        return AppColors.info;
      case 'MESSAGE':
        return AppColors.primaryContainer;
      case 'DISPUTE':
        return AppColors.error;
      case 'PAYMENT':
        return AppColors.warning;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}
