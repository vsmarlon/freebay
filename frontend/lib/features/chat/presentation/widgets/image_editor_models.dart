import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImageEditorResult {
  final Uint8List imageBytes;
  final String? caption;
  final bool viewOnce;

  const ImageEditorResult({
    required this.imageBytes,
    this.caption,
    required this.viewOnce,
  });
}

enum ImageEditorPurpose { chat, post, story }

enum EditorMode { crop, adjust, filter, text, draw, preview }

enum PenStyle { marker, highlighter, eraser }

class DrawStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final PenStyle style;

  const DrawStroke(this.points, this.color, this.width, this.style);
}

class TextOverlay {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;

  const TextOverlay({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });

  TextOverlay copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
