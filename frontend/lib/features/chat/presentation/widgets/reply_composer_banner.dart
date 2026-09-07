import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/widgets/reply_preview_banner.dart';

class ReplyComposerBanner extends StatelessWidget {
  final MessageEntity replyTo;
  final String? currentUserId;
  final String? otherUserName;
  final Color accentColor;
  final VoidCallback onCancel;

  const ReplyComposerBanner({
    super.key,
    required this.replyTo,
    required this.accentColor,
    required this.onCancel,
    this.currentUserId,
    this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerHigh,
        border: Border(top: BorderSide(color: accentColor, width: 2)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: accentColor),
          Spacing.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  replySenderLabel(
                    replyTo,
                    currentUserId: currentUserId,
                    otherUserName: otherUserName,
                  ),
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.previewText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            color: context.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
