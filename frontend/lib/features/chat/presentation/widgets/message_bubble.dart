import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final bool isDark;
  final bool isConsecutive;
  final Color accentColor;
  final DateTime? createdAt;
  final dynamic readAt;
  final dynamic deliveredAt;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isMe,
    required this.isDark,
    this.isConsecutive = false,
    this.accentColor = AppColors.primaryContainer,
    this.createdAt,
    this.readAt,
    this.deliveredAt,
  });

  bool get _isRead => readAt != null;
  bool get _isDelivered => deliveredAt != null;

  @override
  Widget build(BuildContext context) {
    final timeStr = createdAt != null
        ? DateFormat('HH:mm').format(createdAt!)
        : '';

    return Padding(
      padding: EdgeInsets.only(bottom: isConsecutive ? 2 : 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? accentColor
                        : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      color: isMe
                          ? AppColors.onPrimary
                          : (isDark ? AppColors.white : AppColors.darkGray),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                if (timeStr.isNotEmpty)
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
