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
    final productTitle = chat.productTitle;
    Widget tile = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: context.bgColor,
            border: Border(
              left: BorderSide(
                color: chat.unread
                    ? AppColors.primaryContainer
                    : Colors.transparent,
                width: 4,
              ),
              top: BorderSide(color: context.borderColor),
              right: BorderSide(color: context.borderColor),
              bottom: BorderSide(color: context.borderColor),
            ),
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
                              fontFamily: AppTypography.headlineFontFamily,
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
                                : context.textSecondary,
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
                    if (productTitle != null && productTitle.isNotEmpty) ...[
                      Text(
                        productTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Spacing.vXs,
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
                                  : context.textSecondary,
                              fontWeight: chat.unread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!canSwipe) ...[
                          Spacing.hXs,
                          Tooltip(
                            message:
                                'Ações disponíveis apenas após o pedido ser concluído ou cancelado.',
                            child: Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: context.textSecondary,
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

    return tile;
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarUrl = chat.otherAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            image: hasAvatar
                ? DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            color: isDark
                ? context.textSecondary.withAlpha(51)
                : AppColors.lightGray,
          ),
          child: hasAvatar
              ? null
              : Icon(Icons.person, color: context.textPrimary),
        ),
        if (chat.unread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: AppColors.primaryContainer,
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
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
                  ? context.textSecondary.withAlpha(51)
                  : context.surfaceMidColor,
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
                        ? context.textSecondary.withAlpha(51)
                        : context.surfaceMidColor,
                  ),
                  Spacing.vSm,
                  Container(
                    height: 12,
                    width: 150,
                    color: isDark
                        ? context.textSecondary.withAlpha(51)
                        : context.surfaceMidColor,
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
