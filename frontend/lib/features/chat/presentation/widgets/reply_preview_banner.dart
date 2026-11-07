import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/shared/utils/media_url.dart';

/// Resolves whose message is being replied to, for any reply preview surface.
String replySenderLabel(
  MessageEntity message, {
  String? currentUserId,
  String? otherUserName,
}) {
  if (currentUserId != null && message.senderId == currentUserId) return 'Você';
  return otherUserName ?? '';
}

class ReplyPreviewBanner extends StatelessWidget {
  final MessageEntity? replyTo;
  final String? currentUserId;
  final String? otherUserName;
  final VoidCallback? onTap;

  const ReplyPreviewBanner({
    super.key,
    this.replyTo,
    this.currentUserId,
    this.otherUserName,
    this.onTap,
  });

  String get _senderLabel {
    final message = replyTo;
    if (message == null) return '';
    return replySenderLabel(
      message,
      currentUserId: currentUserId,
      otherUserName: otherUserName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reply = replyTo;
    final isDeleted = reply == null;
    final displayText = reply == null
        ? 'Mensagem apagada'
        : reply.viewOnce
        ? l10n(context).chatViewOnce
        : reply.previewText;

    final banner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerHigh,
        border: const Border(
          left: BorderSide(color: AppColors.primaryContainer, width: 3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reply != null &&
              !reply.viewOnce &&
              reply.attachmentUrl != null &&
              (reply.type == MessageType.image ||
                  reply.type == MessageType.gif ||
                  reply.type == MessageType.video)) ...[
            SizedBox(
              width: 36,
              height: 36,
              child: _replyThumbnail(context, reply),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _senderLabel,
                  style: const TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return banner;
    return InkWell(onTap: onTap, child: banner);
  }

  Widget _replyThumbnail(BuildContext context, MessageEntity reply) {
    final url = mediaUrl(reply.attachmentUrl!);
    final fallback = Icon(
      reply.type == MessageType.video
          ? Icons.videocam_outlined
          : Icons.image_outlined,
      color: context.textSecondary,
    );
    if (isPrivateMedia(url)) {
      return Image.network(
        url,
        headers: mediaAuthHeaders(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
