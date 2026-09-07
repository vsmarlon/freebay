import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/time_utils.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';

class ChatListTile extends StatelessWidget {
  final ChatEntity chat;
  final bool isDark;
  final bool canSwipe;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<void> Function() onArchive;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.isDark,
    required this.canSwipe,
    required this.onTap,
    required this.onLongPress,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: chat.unread
                  ? AppColors.primaryContainer
                  : Colors.transparent,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.bgColor,
                  border: Border.all(color: context.borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildAvatar(context),
                    Spacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.otherName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily:
                                        AppTypography.headlineFontFamily,
                                    fontWeight: chat.unread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Spacing.hXs,
                              Text(
                                TimeUtils.timeAgoCompact(chat.timestamp),
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: chat.unread
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: chat.unread
                                      ? AppColors.primaryContainer
                                      : AppColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                          Spacing.vXs,
                          if (chat.threadType == ChatThreadType.order) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              color: isDark
                                  ? AppColors.surfaceContainerLowDark
                                  : AppColors.surfaceContainerHighest,
                              child: const Text(
                                'PEDIDO',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.lastMessage ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    color: chat.unread
                                        ? (isDark
                                              ? AppColors.white
                                              : AppColors.darkGray)
                                        : AppColors.mediumGray,
                                    fontWeight: chat.unread
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (!canSwipe) ...[
                                Spacing.hXs,
                                const Tooltip(
                                  message:
                                      'Ações disponíveis apenas após o pedido ser concluído ou cancelado.',
                                  child: Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (canSwipe) {
      tile = Dismissible(
        key: ValueKey('chat_${chat.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: const BoxDecoration(
            gradient: AppColors.brutalistGradient,
          ),
          child: const Icon(
            Icons.archive,
            color: AppColors.onPrimary,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          await onArchive();
          return false;
        },
        child: tile,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.base,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: tile,
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            image: chat.otherAvatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(chat.otherAvatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: isDark
                ? AppColors.mediumGray.withAlpha(51)
                : AppColors.lightGray,
          ),
          child: chat.otherAvatarUrl == null
              ? Icon(Icons.person, color: context.textPrimary)
              : null,
        ),
        if (chat.unread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                border: Border.all(color: context.bgColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class ChatListLoadingTile extends StatelessWidget {
  final bool isDark;

  const ChatListLoadingTile({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgColor,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              color: isDark
                  ? AppColors.mediumGray.withAlpha(51)
                  : AppColors.lightGray,
            ),
            Spacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 100,
                    color: isDark
                        ? AppColors.mediumGray.withAlpha(51)
                        : AppColors.lightGray,
                  ),
                  Spacing.vSm,
                  Container(
                    height: 12,
                    width: 150,
                    color: isDark
                        ? AppColors.mediumGray.withAlpha(51)
                        : AppColors.lightGray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
