import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/media_editor/domain/editor_models.dart';
import 'package:freebay/features/media_editor/presentation/widgets/draw_palette.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_models.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Bottom toolbar of the image editor: draw palette plus mode tabs.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.mode,
    required this.penStyle,
    required this.drawColor,
    required this.drawWidth,
    required this.onTab,
    required this.onColor,
    required this.onPenStyle,
    required this.onWidth,
    required this.canRedo,
    required this.onRedo,
  });

  final EditorMode mode;
  final PenStyle penStyle;
  final Color drawColor;
  final double drawWidth;
  final ValueChanged<EditorMode> onTab;
  final ValueChanged<Color> onColor;
  final ValueChanged<PenStyle> onPenStyle;
  final ValueChanged<double> onWidth;
  final bool canRedo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      color: context.surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mode == EditorMode.draw)
            DrawPalette(
              color: drawColor,
              strokeKind: switch (penStyle) {
                PenStyle.highlighter => StrokeKind.marker,
                PenStyle.eraser => StrokeKind.eraser,
                _ => StrokeKind.pen,
              },
              widthPx: drawWidth,
              onColor: onColor,
              onStrokeKind: (kind) => onPenStyle(switch (kind) {
                StrokeKind.marker => PenStyle.highlighter,
                StrokeKind.eraser => PenStyle.eraser,
                _ => PenStyle.marker,
              }),
              onWidthPx: onWidth,
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Tab(
                  label: strings.chatEditorCrop,
                  icon: Icons.crop,
                  isSelected: mode == EditorMode.crop,
                  onTap: () => onTab(EditorMode.crop),
                ),
                const SizedBox(width: 8),
                _Tab(
                  label: strings.chatEditorAdjust,
                  icon: Icons.tune,
                  isSelected: mode == EditorMode.adjust,
                  onTap: () => onTab(EditorMode.adjust),
                ),
                const SizedBox(width: 8),
                _Tab(
                  label: strings.chatEditorFilter,
                  icon: Icons.filter_vintage,
                  isSelected: mode == EditorMode.filter,
                  onTap: () => onTab(EditorMode.filter),
                ),
                const SizedBox(width: 8),
                _Tab(
                  label: strings.chatEditorText,
                  icon: Icons.text_fields,
                  isSelected: mode == EditorMode.text,
                  onTap: () => onTab(EditorMode.text),
                ),
                const SizedBox(width: 8),
                _Tab(
                  label: strings.chatEditorDraw,
                  icon: Icons.edit,
                  isSelected: mode == EditorMode.draw,
                  onTap: () => onTab(EditorMode.draw),
                ),
                const SizedBox(width: 8),
                _Tab(
                  label: strings.chatEditorPreview,
                  icon: Icons.preview,
                  isSelected: mode == EditorMode.preview,
                  onTap: () => onTab(EditorMode.preview),
                ),
                if (mode == EditorMode.draw)
                  BrutalistIconButton(
                    icon: Icons.redo,
                    semanticLabel: strings.mediaEditorRedo,
                    onTap: canRedo ? onRedo : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: isSelected ? AppColors.primaryContainer : Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.onPrimary : context.textPrimary,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.onPrimary
                        : context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
