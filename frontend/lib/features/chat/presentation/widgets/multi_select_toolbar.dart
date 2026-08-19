import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

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

  const MultiSelectToolbar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onDelete,
    required this.onForward,
    required this.onStar,
    required this.onShare,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
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
            tooltip: 'Cancelar seleção',
          ),
          const SizedBox(width: 8),
          // Selected count badge
          Expanded(
            child: Text(
              '$selectedCount selecionada${selectedCount == 1 ? '' : 's'}',
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
            icon: Icons.reply,
            onTap: selectedCount == 1 ? onReply : null,
            tooltip: 'Responder',
          ),
          _ToolbarButton(
            icon: Icons.star_outline,
            onTap: onStar,
            tooltip: 'Favoritar',
          ),
          _ToolbarButton(
            icon: Icons.share_outlined,
            onTap: onShare,
            tooltip: 'Compartilhar',
          ),
          _ToolbarButton(
            icon: Icons.forward,
            onTap: onForward,
            tooltip: 'Encaminhar',
          ),
          _ToolbarButton(
            icon: Icons.delete_outline,
            onTap: onDelete,
            tooltip: 'Apagar',
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
