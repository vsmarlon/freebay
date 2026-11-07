import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

import '../../domain/editor_models.dart';

/// Paleta de desenho: cores (+ picker custom), tipos de pincel e espessuras.
/// A espessura chega em px; o chamador converte para widthFactor com a
/// largura do canvas.
class DrawPalette extends StatelessWidget {
  const DrawPalette({
    super.key,
    required this.strokeKind,
    required this.color,
    required this.widthPx,
    required this.onStrokeKind,
    required this.onColor,
    required this.onWidthPx,
    this.blur = false,
  });

  final StrokeKind strokeKind;
  final Color color;
  final double widthPx;
  final ValueChanged<StrokeKind> onStrokeKind;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onWidthPx;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    // Brutalist horizontal scroll, 0px radius
    final colors = [
      AppColors.primaryContainer,
      Colors.white,
      Colors.black,
      const Color(0xFFE53935), // Red
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFFDD835), // Yellow
      const Color(0xFFFB8C00), // Orange
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceHighColor,
        border: Border(
          bottom: BorderSide(color: context.surfaceColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 8),
                ...colors.map(
                  (c) => Semantics(
                    button: true,
                    selected: color == c && strokeKind != StrokeKind.eraser,
                    label: strings.chatEditorChooseColor,
                    child: GestureDetector(
                      onTap: () => onColor(c),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: c,
                          border: Border.all(
                            color: color == c && strokeKind != StrokeKind.eraser
                                ? context.textPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showEditorColorPicker(context, onPick: onColor),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      border: Border.all(color: context.textPrimary),
                    ),
                    child: Semantics(
                      button: true,
                      label: strings.chatEditorChooseCustomColor,
                      child: Icon(
                        Icons.palette,
                        size: 18,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 8),
                _ToolBtn(
                  icon: Icons.edit,
                  label: strings.chatEditorPenMarker,
                  isSelected: strokeKind == StrokeKind.pen,
                  onTap: () => onStrokeKind(StrokeKind.pen),
                ),
                _ToolBtn(
                  icon: Icons.brush,
                  label: strings.chatEditorPenHighlighter,
                  isSelected: strokeKind == StrokeKind.marker,
                  onTap: () => onStrokeKind(StrokeKind.marker),
                ),
                _ToolBtn(
                  icon: Icons.auto_awesome,
                  label: strings.mediaEditorNeon,
                  isSelected: strokeKind == StrokeKind.neon,
                  onTap: () => onStrokeKind(StrokeKind.neon),
                ),
                _ToolBtn(
                  icon: Icons.cleaning_services,
                  label: strings.chatEditorPenEraser,
                  isSelected: strokeKind == StrokeKind.eraser,
                  onTap: () => onStrokeKind(StrokeKind.eraser),
                ),
                if (blur)
                  _ToolBtn(
                    icon: Icons.blur_on,
                    label: strings.mediaEditorBlur,
                    isSelected: strokeKind == StrokeKind.blur,
                    onTap: () => onStrokeKind(StrokeKind.blur),
                  ),
                const SizedBox(width: 16),
                for (final width in [4.0, 8.0, 14.0, 24.0])
                  Semantics(
                    button: true,
                    selected: widthPx == width,
                    label: strings.chatEditorStrokeWidth(width.toInt()),
                    child: GestureDetector(
                      onTap: () => onWidthPx(width),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: widthPx == width
                            ? context.surfaceColor
                            : Colors.transparent,
                        child: Center(
                          child: Container(
                            width: width > 16 ? 16 : width,
                            height: width > 16 ? 16 : width,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: isSelected ? context.textPrimary : Colors.transparent,
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? context.surfaceColor : context.textPrimary,
          ),
        ),
      ),
    );
  }
}

void showEditorColorPicker(
  BuildContext context, {
  required ValueChanged<Color> onPick,
}) {
  final colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
  ];

  showBrutalistSheet<void>(
    context: context,
    padding: const EdgeInsets.all(16),
    builder: (context) {
      return GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final c = colors[index];
          return GestureDetector(
            onTap: () {
              onPick(c);
              Navigator.of(context).pop();
            },
            child: Container(color: c),
          );
        },
      );
    },
  );
}
