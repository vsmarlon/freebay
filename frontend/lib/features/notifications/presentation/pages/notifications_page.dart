import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:freebay/core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificações',
          overflow: TextOverflow.visible,
        ),
        actions: [
          InkWell(
            onTap: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível carregar suas notificações.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.onSurface,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puxe para atualizar ou tente novamente em instantes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => ref.read(notificationsProvider.notifier).refresh(),
                  child: Container(
                    height: 44,
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
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        color: _getIconColor(notification.type),
        child: Icon(
          _getIcon(notification.type),
          color: Colors.white,
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
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            timeAgo,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
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
        return Colors.green;
      case 'FOLLOW':
        return Colors.blue;
      case 'MESSAGE':
        return Colors.purple;
      case 'DISPUTE':
        return Colors.red;
      case 'PAYMENT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }
}
