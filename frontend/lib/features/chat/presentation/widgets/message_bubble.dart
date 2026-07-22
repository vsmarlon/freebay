import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'reply_preview_banner.dart';
import 'reaction_bar.dart';
import 'image_message_bubble.dart';
import 'link_preview_card.dart';
import 'location_message_bubble.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool isDark;
  final bool isConsecutive;
  final Color accentColor;
  final ValueChanged<String>? onReactionTap;
  final void Function(String emoji, LongPressStartDetails details)?
  onReactionLongPress;
  final VoidCallback? onSwipeToReply;
  final VoidCallback? onLongPressMessage;
  final VoidCallback? onReplyTap;
  final String? currentUserId;
  final String? otherUserName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isDark,
    this.isConsecutive = false,
    this.accentColor = AppColors.primaryContainer,
    this.onReactionTap,
    this.onReactionLongPress,
    this.onSwipeToReply,
    this.onLongPressMessage,
    this.onReplyTap,
    this.currentUserId,
    this.otherUserName,
  });

  bool get _isRead => message.readAt != null;
  bool get _isDelivered => message.deliveredAt != null;
  bool get _isDeleted => message.deletedAt != null;
  bool get _hasReply => message.replyTo != null;
  bool get _hasReactions => message.reactions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(bottom: isConsecutive ? 2 : 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Dismissible(
            key: ValueKey(message.id),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (_) async {
              onSwipeToReply?.call();
              return false;
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 12),
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              child: Icon(
                Icons.reply,
                color: AppColors.primaryContainer,
                size: 20,
              ),
            ),
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: GestureDetector(
                    onLongPress: onLongPressMessage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isDeleted
                            ? (isDark
                                  ? AppColors.surfaceContainerDark
                                  : AppColors.surfaceContainerHigh)
                            : isMe
                            ? accentColor
                            : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceContainerLow),
                      ),
                      child: _buildContent(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Time + read status row
          Padding(
            padding: EdgeInsets.only(
              top: 2,
              left: isMe ? 0 : 4,
              right: isMe ? 4 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _ReadStatusIcon(isRead: _isRead, isDelivered: _isDelivered),
                ],
              ],
            ),
          ),
          // Reaction bar below bubble
          if (_hasReactions)
            ReactionBar(
              reactions: message.reactions,
              onReactionTap: onReactionTap,
              onReactionLongPress: onReactionLongPress,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isDeleted) {
      return Text(
        'Mensagem apagada',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: context.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply preview
        if (_hasReply) ...[
          ReplyPreviewBanner(
            replyTo: message.replyTo,
            currentUserId: currentUserId,
            otherUserName: otherUserName,
            onTap: onReplyTap,
          ),
          const SizedBox(height: 6),
        ],
        // Main content by type
        _buildTypedContent(context),
      ],
    );
  }

  Widget _buildTypedContent(BuildContext context) {
    final type = message.type.toUpperCase();

    switch (type) {
      case 'IMAGE':
      case 'GIF':
        return ImageMessageBubble(imageUrl: message.attachmentUrl, isMe: isMe);
      case 'LOCATION':
        return LocationMessageBubble(
          metadata: message.metadata?.toJson(),
          isMe: isMe,
        );
      case 'PRODUCT_CARD':
        return _ProductCardContent(message: message);
      case 'TEXT':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.content != null && message.content!.isNotEmpty)
              Text(
                message.content!,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  color: isMe
                      ? AppColors.onPrimary
                      : (isDark ? AppColors.white : AppColors.darkGray),
                ),
              ),
            // Link preview below text
            if (message.metadata != null) ...[
              const SizedBox(height: 6),
              LinkPreviewCard(metadata: message.metadata),
            ],
          ],
        );
    }
  }
}

class _ProductCardContent extends StatelessWidget {
  final MessageEntity message;

  const _ProductCardContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final meta = message.metadata?.toJson();
    final title = meta?['title'] as String? ?? '';
    final price = meta?['price'];
    final priceStr = price != null
        ? 'R\$ ${price is num ? (price / 100).toStringAsFixed(2) : price.toString()}'
        : '';

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (priceStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
              ),
              child: Text(
                priceStr,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadStatusIcon extends StatelessWidget {
  final bool isRead;
  final bool isDelivered;

  const _ReadStatusIcon({required this.isRead, required this.isDelivered});

  @override
  Widget build(BuildContext context) {
    if (isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 14, color: AppColors.primaryContainer),
        ],
      );
    }
    if (isDelivered) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 14, color: context.textSecondary),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(Icons.done, size: 14, color: context.textSecondary)],
    );
  }
}
