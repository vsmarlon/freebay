import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/chat/data/entities/chat_entity.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      padding: EdgeInsets.zero,
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
              bottom: BorderSide(color: context.borderSoftColor, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          localizedTimeAgo(
                            context,
                            chat.timestamp,
                            compact: true,
                          ),
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
                        child: Text(
                          l10n(context).chatOrderLabel,
                          style: const TextStyle(
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

    return RepaintBoundary(child: tile);
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
                    image: CachedNetworkImageProvider(avatarUrl),
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
