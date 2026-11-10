import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

import '../../domain/editor_models.dart';

/// Render único de camada de texto — usado no preview E no export.
class TextLayerView extends StatelessWidget {
  const TextLayerView({
    super.key,
    required this.layer,
    required this.canvasWidth,
  });
  final TextLayer layer;
  final double canvasWidth;

  @override
  Widget build(BuildContext context) {
    final size = canvasWidth * layer.sizeFactor;
    // Exported artwork keeps its contrast independent of the app theme.
    final onSolid =
        ThemeData.estimateBrightnessForColor(layer.color) == Brightness.dark
        ? AppColors.white
        : const Color(0xFF000000);
    final foreground = layer.bg == TextBg.solid ? onSolid : layer.color;
    final background = switch (layer.bg) {
      TextBg.none => null,
      TextBg.solid => layer.color,
      TextBg.translucent => const Color(0x8C000000),
    };

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: canvasWidth * .9),
      child: Container(
        padding: background == null
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
        decoration: background == null
            ? null
            : BoxDecoration(color: background),
        child: Text(
          layer.text,
          textAlign: layer.align,
          style: AppTypography.h2.copyWith(
            fontFamily: layer.font,
            fontSize: size,
            height: 1.15,
            color: foreground,
            shadows: background == null
                ? const [
                    Shadow(
                      offset: AppDepth.shadowOffsetSmall,
                      color: Color(0x66000000),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

/// Adesivos: emoji solto e pílulas próprias do marketplace (preço, VENDIDO,
/// localização, link).
class StickerLayerView extends StatelessWidget {
  const StickerLayerView({
    super.key,
    required this.layer,
    required this.canvasWidth,
  });
  final StickerLayer layer;
  final double canvasWidth;

  @override
  Widget build(BuildContext context) {
    final size = canvasWidth * layer.sizeFactor;
    return switch (layer.kind) {
      StickerKind.emoji => Text(
        layer.payload,
        style: TextStyle(fontSize: size, height: 1),
      ),
      StickerKind.price => _pill(
        size,
        layer.payload,
        const Color(0xFF16A34A),
        Icons.sell,
      ),
      StickerKind.sold => _pill(
        size,
        layer.payload,
        const Color(0xFFDC2626),
        null,
      ),
      StickerKind.location => _pill(
        size,
        layer.payload,
        AppColors.white,
        Icons.place,
        dark: true,
      ),
      StickerKind.link => _pill(
        size,
        layer.payload,
        AppColors.white,
        Icons.link,
        dark: true,
      ),
    };
  }

  Widget _pill(
    double size,
    String text,
    Color color,
    IconData? icon, {
    bool dark = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.sm,
      vertical: Spacing.xs,
    ),
    decoration: BoxDecoration(
      color: color,
      boxShadow: AppDepth.hardSmall(const Color(0x33000000)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: size * .5,
            color: dark ? const Color(0xDD000000) : AppColors.white,
          ),
          Spacing.hXs,
        ],
        Text(
          text,
          style: AppTypography.h2
              .weight(800)
              .copyWith(
                fontSize: size * .45,
                color: dark ? const Color(0xDD000000) : AppColors.white,
              ),
        ),
      ],
    ),
  );
}
