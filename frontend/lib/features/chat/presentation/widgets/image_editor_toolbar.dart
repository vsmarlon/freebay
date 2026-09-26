import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/draw_palette.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_models.dart';

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
  });

  final EditorMode mode;
  final PenStyle penStyle;
  final Color drawColor;
  final double drawWidth;
  final ValueChanged<EditorMode> onTab;
  final ValueChanged<Color> onColor;
  final ValueChanged<PenStyle> onPenStyle;
  final ValueChanged<double> onWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mode == EditorMode.draw)
            DrawPalette(
              drawColor: drawColor,
              penStyle: penStyle,
              drawWidth: drawWidth,
              onColor: onColor,
              onPenStyle: onPenStyle,
              onWidth: onWidth,
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Tab(
                  label: 'CROP',
                  icon: Icons.crop,
                  isSelected: mode == EditorMode.crop,
                  onTap: () => onTab(EditorMode.crop),
                ),
                _Tab(
                  label: 'ADJUST',
                  icon: Icons.tune,
                  isSelected: mode == EditorMode.adjust,
                  onTap: () => onTab(EditorMode.adjust),
                ),
                _Tab(
                  label: 'FILTER',
                  icon: Icons.filter_vintage,
                  isSelected: mode == EditorMode.filter,
                  onTap: () => onTab(EditorMode.filter),
                ),
                _Tab(
                  label: 'TEXT',
                  icon: Icons.text_fields,
                  isSelected: mode == EditorMode.text,
                  onTap: () => onTab(EditorMode.text),
                ),
                _Tab(
                  label: 'DRAW',
                  icon: Icons.edit,
                  isSelected: mode == EditorMode.draw,
                  onTap: () => onTab(EditorMode.draw),
                ),
                _Tab(
                  label: 'PREVIEW',
                  icon: Icons.preview,
                  isSelected: mode == EditorMode.preview,
                  onTap: () => onTab(EditorMode.preview),
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
    return Expanded(
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
                  color: isSelected ? AppColors.onPrimary : context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
