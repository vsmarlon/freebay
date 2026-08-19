import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/widgets/product_card_bubble.dart';
import 'package:freebay/features/chat/presentation/widgets/offer_message_bubble.dart';
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
  final bool showTimestamp;
  final Color accentColor;
  final ValueChanged<String>? onReactionTap;
  final void Function(String emoji, LongPressStartDetails details)?
  onReactionLongPress;
  final VoidCallback? onSwipeToReply;
  final VoidCallback? onLongPressMessage;
  final VoidCallback? onReplyTap;
  final String? currentUserId;
  final String? otherUserName;
  final VoidCallback? onViewOnceReveal;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isDark,
    this.isConsecutive = false,
    this.showTimestamp = true,
    this.accentColor = AppColors.primaryContainer,
    this.onReactionTap,
    this.onReactionLongPress,
    this.onSwipeToReply,
    this.onLongPressMessage,
    this.onReplyTap,
    this.currentUserId,
    this.otherUserName,
    this.onViewOnceReveal,
  });

  bool get _isRead => message.readAt != null;
  bool get _isDelivered => message.deliveredAt != null;
  bool get _isDeleted => message.deletedAt != null;
  bool get _hasReply => message.replyTo != null;
  bool get _hasReactions => message.reactions.isNotEmpty;
  bool get _isViewOnceRevealed => message.viewOnce && message.readAt != null;
  bool get _isViewOnceLocked => message.viewOnce && message.readAt == null;

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
          if (showTimestamp)
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

    // View-once locked bubble
    if (_isViewOnceLocked) {
      return GestureDetector(
        onTap: onViewOnceReveal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 24,
                color: isMe
                    ? AppColors.onPrimary.withValues(alpha: 0.7)
                    : context.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                'Mensagem de\nvisualização única',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isMe
                      ? AppColors.onPrimary.withValues(alpha: 0.7)
                      : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // View-once already revealed
    if (_isViewOnceRevealed) {
      return _buildRevealedContent(context);
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

  Widget _buildRevealedContent(BuildContext context) {
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
        _buildTypedContent(context),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 12,
              color: context.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Mensagem já visualizada',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
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
        return LocationMessageBubble(metadata: message.metadata, isMe: isMe);
      case 'PRODUCT_CARD':
        return ProductCardBubble(message: message, isMe: isMe);
      case 'OFFER':
        return OfferMessageBubble(message: message, isMe: isMe);
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
