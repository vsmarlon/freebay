import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_models.dart';

/// Horizontal draw-tools palette of the image editor: colors, pens, widths.
class DrawPalette extends StatelessWidget {
  const DrawPalette({
    super.key,
    required this.drawColor,
    required this.penStyle,
    required this.drawWidth,
    required this.onColor,
    required this.onPenStyle,
    required this.onWidth,
  });

  final Color drawColor;
  final PenStyle penStyle;
  final double drawWidth;
  final ValueChanged<Color> onColor;
  final ValueChanged<PenStyle> onPenStyle;
  final ValueChanged<double> onWidth;

  @override
  Widget build(BuildContext context) {
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
                  (c) => GestureDetector(
                    onTap: () => onColor(c),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: c,
                        border: Border.all(
                          color: drawColor == c && penStyle != PenStyle.eraser
                              ? context.textPrimary
                              : Colors.transparent,
                          width: 2,
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
                    child: Icon(
                      Icons.palette,
                      size: 18,
                      color: context.textPrimary,
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
                  isSelected: penStyle == PenStyle.marker,
                  onTap: () => onPenStyle(PenStyle.marker),
                ),
                _ToolBtn(
                  icon: Icons.brush,
                  isSelected: penStyle == PenStyle.highlighter,
                  onTap: () => onPenStyle(PenStyle.highlighter),
                ),
                _ToolBtn(
                  icon: Icons.cleaning_services,
                  isSelected: penStyle == PenStyle.eraser,
                  onTap: () => onPenStyle(PenStyle.eraser),
                ),
                const SizedBox(width: 16),
                for (final width in [4.0, 8.0, 14.0, 24.0])
                  GestureDetector(
                    onTap: () => onWidth(width),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: drawWidth == width
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
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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

  showModalBottomSheet(
    context: context,
    backgroundColor: context.surfaceColor,
    shape: const RoundedRectangleBorder(),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
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
          ),
        ),
      );
    },
  );
}
