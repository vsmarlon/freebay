import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';

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
    final isDeleted = replyTo == null;
    final displayText = isDeleted ? 'Mensagem apagada' : replyTo!.previewText;

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
    );

    if (onTap == null) return banner;
    return InkWell(onTap: onTap, child: banner);
  }
}
