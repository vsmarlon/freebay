import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ImageEditorRouteRequest {
  ImageEditorRouteRequest({
    required this.imageBytes,
    required this.purpose,
    required this.onComplete,
    this.initialViewOnce = false,
  }) : requestId = '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  static final Map<String, ImageEditorRouteRequest> _pending = {};
  static int _nextId = 0;

  final String requestId;
  final Uint8List imageBytes;
  final ImageEditorPurpose purpose;
  final bool initialViewOnce;
  final Future<bool> Function(ImageEditorResult result) onComplete;

  bool get isValid => imageBytes.isNotEmpty;

  static ImageEditorRouteRequest? resolve(GoRouterState state) {
    final extra = state.extra;
    if (extra is ImageEditorRouteRequest) return extra;
    final requestId = state.uri.queryParameters['requestId'];
    return requestId == null ? null : _pending[requestId];
  }

  Future<T?> push<T>(BuildContext context, String route) async {
    if (!isValid) return null;
    _pending[requestId] = this;
    try {
      return await context.push<T>('$route?requestId=$requestId', extra: this);
    } finally {
      _pending.remove(requestId);
    }
  }
}

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
  final String id;
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final double rotation;
  final double scale;
  final TextAlign alignment;
  final String fontFamily;
  final Color? backgroundColor;

  TextOverlay({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    String? id,
    this.rotation = 0,
    this.scale = 1,
    this.alignment = TextAlign.center,
    this.fontFamily = 'SpaceGrotesk',
    this.backgroundColor,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}-${_overlayId++}';

  static int _overlayId = 0;

  TextOverlay copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
    double? rotation,
    double? scale,
    TextAlign? alignment,
    String? fontFamily,
    Color? backgroundColor,
    bool clearBackground = false,
  }) {
    return TextOverlay(
      id: id,
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      alignment: alignment ?? this.alignment,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColor: clearBackground
          ? null
          : backgroundColor ?? this.backgroundColor,
    );
  }
}
