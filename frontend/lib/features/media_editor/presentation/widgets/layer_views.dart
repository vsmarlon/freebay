import 'package:flutter/material.dart';

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
    final onSolid =
        ThemeData.estimateBrightnessForColor(layer.color) == Brightness.dark
        ? Colors.white
        : Colors.black;
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
            : EdgeInsets.symmetric(horizontal: size * .5, vertical: size * .25),
        decoration: background == null
            ? null
            : BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(size * .35),
              ),
        child: Text(
          layer.text,
          textAlign: layer.align,
          style: TextStyle(
            fontFamily: layer.font,
            fontSize: size,
            height: 1.15,
            color: foreground,
            fontWeight: FontWeight.w700,
            shadows: background == null
                ? const [Shadow(blurRadius: 6, color: Color(0x66000000))]
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
        Colors.white,
        Icons.place,
        dark: true,
      ),
      StickerKind.link => _pill(
        size,
        layer.payload,
        Colors.white,
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
    padding: EdgeInsets.symmetric(horizontal: size * .35, vertical: size * .2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size),
      boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x33000000))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: size * .5,
            color: dark ? Colors.black87 : Colors.white,
          ),
          SizedBox(width: size * .15),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: size * .45,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.black87 : Colors.white,
          ),
        ),
      ],
    ),
  );
}
