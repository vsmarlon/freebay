import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/utils/date_utils.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/presentation/widgets/product_card_bubble.dart';
import 'reply_preview_banner.dart';
import 'reaction_bar.dart';
import 'image_message_bubble.dart';
import 'audio_message_bubble.dart';
import 'video_message_bubble.dart';
import 'link_preview_card.dart';
import 'location_message_bubble.dart';
import 'message_bubble/expandable_text_message.dart';
import 'message_bubble/read_status_icon.dart';

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
  final bool isStarred;
  final VoidCallback? onImageTap;

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
    this.isStarred = false,
    this.onImageTap,
  });

  bool get _isRead => message.readAt != null;
  bool get _isDelivered => message.deliveredAt != null;
  bool get _isDeleted => message.deletedAt != null;
  bool get _hasReply => message.replyTo != null;
  bool get _hasReactions => message.reactions.isNotEmpty;
  bool get _isViewOnceRevealed => message.viewOnce && message.readAt != null;
  bool get _isViewOnceLocked => message.viewOnce && message.readAt == null;
  bool get _isForwarded => message.metadata?['isForwarded'] == true;

  @override
  Widget build(BuildContext context) {
    final timeStr = formatMessageTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(bottom: isConsecutive ? 2 : 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Dismissible(
            key: ValueKey(message.id),
            confirmDismiss: (_) async {
              onSwipeToReply?.call();
              return false;
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 12),
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              child: const Icon(
                Icons.reply,
                color: AppColors.primaryContainer,
                size: 20,
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12),
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              child: const Icon(
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
                  if (isStarred) ...[
                    const Icon(
                      Icons.star,
                      size: 11,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 4),
                  ],
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
                    ReadStatusIcon(isRead: _isRead, isDelivered: _isDelivered),
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
        onTap: isMe ? null : onViewOnceReveal,
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
      return _buildMessageContent(context, showViewedFooter: true);
    }

    return _buildMessageContent(context);
  }

  Widget _buildMessageContent(
    BuildContext context, {
    bool showViewedFooter = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Forwarded badge
        if (_isForwarded) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.forward,
                  size: 13,
                  color: isMe
                      ? AppColors.onPrimary.withValues(alpha: 0.75)
                      : context.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Encaminhada',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: isMe
                        ? AppColors.onPrimary.withValues(alpha: 0.75)
                        : context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        if (showViewedFooter) ...[
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
      ],
    );
  }

  Widget _buildTypedContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
      case MessageType.gif:
        return ImageMessageBubble(
          imageUrl: message.attachmentUrl,
          isMe: isMe,
          onTapImage: onImageTap,
        );
      case MessageType.video:
        return VideoMessageBubble(videoUrl: message.attachmentUrl, isMe: isMe);
      case MessageType.audio:
        final rawDuration = message.metadata?['durationMs'];
        return AudioMessageBubble(
          audioUrl: message.attachmentUrl,
          isMe: isMe,
          durationMs: rawDuration is int ? rawDuration : null,
        );
      case MessageType.location:
        return LocationMessageBubble(metadata: message.metadata, isMe: isMe);
      case MessageType.productCard:
        return ProductCardBubble(message: message, isMe: isMe);
      case MessageType.unknown:
        return _buildMessageContent(context);
      case MessageType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.content != null && message.content!.isNotEmpty)
              ExpandableTextMessage(text: message.content!, isMe: isMe),
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
