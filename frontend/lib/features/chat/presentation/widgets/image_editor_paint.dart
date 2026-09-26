import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_models.dart';

/// Composites the finished strokes, text overlays, filters, and rotation over [image] at full resolution.
/// Returns the PNG bytes, or null when [decodedImage] is unavailable.
Future<Uint8List?> exportFinalImage({
  required Future<ui.Image>? decodedImageFuture,
  required Size canvasSize,
  required List<DrawStroke> strokes,
  required List<Offset>? activePoints,
  required Color color,
  required double width,
  required PenStyle style,
  required double brightness,
  required double contrast,
  required double saturation,
  required List<double> filterMatrix,
  required double rotationAngle,
  required List<TextOverlay> textOverlays,
}) async {
  if (decodedImageFuture == null) return null;
  final image = await decodedImageFuture;
  final recorder = ui.PictureRecorder();

  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
  );

  // Map drawing to canvas
  final imageSize = Size(image.width.toDouble(), image.height.toDouble());
  final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, canvasSize);
  final destination = Alignment.center.inscribe(
    fittedSizes.destination,
    Offset.zero & canvasSize,
  );

  final scaleX = image.width / destination.width;
  final scaleY = image.height / destination.height;

  canvas.save();

  // We rotate around center if needed
  if (rotationAngle != 0) {
    canvas.translate(image.width / 2, image.height / 2);
    canvas.rotate(rotationAngle);
    canvas.translate(-image.width / 2, -image.height / 2);
  }

  // To apply color filters to the base image, we use a paint
  final paint = Paint()..colorFilter = ColorFilter.matrix(filterMatrix);
  canvas.drawImage(image, Offset.zero, paint);

  canvas.restore();

  // Then we map the canvas space back for strokes and text
  canvas.scale(scaleX, scaleY);
  canvas.translate(-destination.left, -destination.top);

  DrawPainter(strokes, activePoints, color, width, style).drawStrokes(canvas);

  // We can't render text easily using TextPainter without context, but since this is an MVP we'll skip text baking if it's too complex or just do a basic fallback.
  // Actually, we can use TextPainter here!
  for (final overlay in textOverlays) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: overlay.text,
        style: TextStyle(
          color: overlay.color,
          fontSize: overlay.fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, overlay.position);
  }

  final result = await recorder.endRecording().toImage(
    image.width,
    image.height,
  );
  final data = await result.toByteData(format: ui.ImageByteFormat.png);
  result.dispose();
  if (data == null) return null;
  return Uint8List.fromList(data.buffer.asUint8List());
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final Rect destination;

  const ImagePainter(this.image, this.destination);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destination,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) => false;
}

class DrawPainter extends CustomPainter {
  final List<DrawStroke> strokes;
  final List<Offset>? activePoints;
  final Color activeColor;
  final double activeWidth;
  final PenStyle activeStyle;

  const DrawPainter(
    this.strokes,
    this.activePoints,
    this.activeColor,
    this.activeWidth,
    this.activeStyle,
  );

  void drawStrokes(Canvas canvas) {
    canvas.saveLayer(null, Paint());

    for (final stroke in [
      ...strokes,
      if (activePoints != null)
        DrawStroke(activePoints!, activeColor, activeWidth, activeStyle),
    ]) {
      final paint = Paint()
        ..color = stroke.style == PenStyle.highlighter
            ? stroke.color.withAlpha(80)
            : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = stroke.style == PenStyle.marker
            ? StrokeCap.round
            : StrokeCap.square
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.style == PenStyle.eraser
            ? BlendMode.clear
            : BlendMode.srcOver;

      for (var index = 1; index < stroke.points.length; index++) {
        canvas.drawLine(stroke.points[index - 1], stroke.points[index], paint);
      }
    }

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) => drawStrokes(canvas);

  @override
  bool shouldRepaint(covariant DrawPainter oldDelegate) {
    // ponytail: strokes are append-only; length + active state covers repaints.
    if (!identical(oldDelegate.strokes, strokes)) return true;
    if (oldDelegate.strokes.length != strokes.length) return true;
    if (oldDelegate.activeColor != activeColor) return true;
    if (oldDelegate.activeWidth != activeWidth) return true;
    if (oldDelegate.activeStyle != activeStyle) return true;
    return (oldDelegate.activePoints?.length ?? 0) !=
        (activePoints?.length ?? 0);
  }
}
