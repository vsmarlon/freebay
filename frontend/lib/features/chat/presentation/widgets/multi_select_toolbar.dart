import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// The selection-mode toolbar that replaces the [ChatHeader] when one or more
/// messages are long-pressed in the chat conversation.
///
/// Provides bulk actions: Delete, Forward, Star, Share, and Reply.
/// All actions call back to the parent widget which owns the selection state.
class MultiSelectToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final VoidCallback onStar;
  final VoidCallback onShare;
  final VoidCallback onReply;
  final VoidCallback onCopy;

  const MultiSelectToolbar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onDelete,
    required this.onForward,
    required this.onStar,
    required this.onShare,
    required this.onReply,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 4,
        left: 4,
        right: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLow,
        border: const Border(
          bottom: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
      ),
      child: Row(
        children: [
          // Close selection mode
          _ToolbarButton(
            icon: Icons.close,
            onTap: onClose,
            tooltip: strings.chatCancelSelection,
          ),
          const SizedBox(width: 8),
          // Selected count badge
          Expanded(
            child: Text(
              strings.chatSelectedCount(selectedCount),
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
          ),
          // Actions (right-aligned)
          _ToolbarButton(
            icon: Icons.content_copy_outlined,
            onTap: onCopy,
            tooltip: strings.chatCopy,
          ),
          _ToolbarButton(
            icon: Icons.reply,
            onTap: selectedCount == 1 ? onReply : null,
            tooltip: strings.chatReply,
          ),
          _ToolbarButton(
            icon: Icons.star_outline,
            onTap: onStar,
            tooltip: strings.chatFavorite,
          ),
          _ToolbarButton(
            icon: Icons.share_outlined,
            onTap: onShare,
            tooltip: strings.commonShare,
          ),
          _ToolbarButton(
            icon: Icons.forward,
            onTap: onForward,
            tooltip: strings.chatForward,
          ),
          _ToolbarButton(
            icon: Icons.delete_outline,
            onTap: onDelete,
            tooltip: strings.chatDelete,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap == null
        ? context.textSecondary.withValues(alpha: 0.4)
        : (color ?? context.textPrimary);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 22, color: effectiveColor),
          ),
        ),
      ),
    );
  }
}
