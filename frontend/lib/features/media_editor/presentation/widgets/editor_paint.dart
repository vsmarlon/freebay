import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/editor_models.dart';

/// Pinceladas de desenho (caneta/marcador/neon/borracha), normalizadas 0..1.
/// A borracha apaga só o desenho (BlendMode.clear) — nunca texto/blur.
class DrawingPainter extends CustomPainter {
  DrawingPainter({required this.strokes, this.live});
  final List<Stroke> strokes;
  final Stroke? live;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint()); // isola a borracha
    for (final s in [...strokes, ?live]) {
      final path = _smooth(s.points, size);
      if (path == null) continue;
      final w = size.width * s.widthFactor;
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      switch (s.kind) {
        case StrokeKind.pen:
          canvas.drawPath(
            path,
            base
              ..color = s.color
              ..strokeWidth = w
              ..strokeCap = StrokeCap.round,
          );
        case StrokeKind.marker:
          // translúcido, ponta quadrada ("marca-texto")
          canvas.drawPath(
            path,
            base
              ..color = s.color.withAlpha(115)
              ..strokeWidth = w * 2.2
              ..strokeCap = StrokeCap.square,
          );
        case StrokeKind.neon:
          // glow colorido + miolo branco
          canvas.drawPath(
            path,
            Paint.from(base)
              ..color = s.color
              ..strokeWidth = w * 2.4
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
          canvas.drawPath(
            path,
            Paint.from(base)
              ..color = const ui.Color(0xFFFFFFFF)
              ..strokeWidth = w * .8
              ..strokeCap = StrokeCap.round,
          );
        case StrokeKind.eraser:
          canvas.drawPath(
            path,
            base
              ..blendMode = BlendMode.clear
              ..strokeWidth = w * 2
              ..strokeCap = StrokeCap.round,
          );
        case StrokeKind.blur:
          break; // renderizado por BlurStrokesPainter
      }
    }
    canvas.restore();
  }

  Path? _smooth(List<Offset> normalized, Size size) {
    final p = [
      for (final o in normalized) Offset(o.dx * size.width, o.dy * size.height),
    ];
    if (p.isEmpty) return null;
    final path = Path();
    path.moveTo(p.first.dx, p.first.dy);
    if (p.length == 1) {
      path.lineTo(p.first.dx + .1, p.first.dy);
      return path;
    }
    for (var i = 1; i < p.length - 1; i++) {
      final mid = (p[i] + p[i + 1]) / 2;
      path.quadraticBezierTo(p[i].dx, p[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(DrawingPainter old) =>
      !identical(old.strokes, strokes) || !identical(old.live, live);
}

/// Pincel de blur (borrar áreas da foto): cópia borrada da imagem recortada
/// pelos traços de blur via saveLayer + BlendMode.srcIn (seção 9.3 do guia).
class BlurStrokesPainter extends CustomPainter {
  BlurStrokesPainter({
    required this.image,
    required this.matrix,
    required this.strokes,
    this.sigma = 18,
  });

  final ui.Image image;
  final Matrix4 matrix;
  final List<Stroke> strokes;
  final double sigma;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint()); // L1: máscara dos traços
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final path = Path()
        ..moveTo(
          s.points.first.dx * size.width,
          s.points.first.dy * size.height,
        );
      for (final o in s.points.skip(1)) {
        path.lineTo(o.dx * size.width, o.dy * size.height);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = size.width * s.widthFactor * 3
          ..color = Colors.black,
      );
    }
    canvas.saveLayer(
      bounds,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
    );
    canvas.transform(matrix.storage);
    canvas.drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(BlurStrokesPainter old) =>
      old.strokes != strokes || old.matrix != matrix;
}

/// Vinheta radial (ajuste "Vinheta"), parte do overlay exportável.
class VignetteOverlay extends StatelessWidget {
  const VignetteOverlay({super.key, required this.strength});
  final double strength;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        radius: .95,
        colors: [
          Colors.transparent,
          Colors.black.withAlpha((0.65 * strength * 255).round()),
        ],
        stops: const [.55, 1],
      ),
    ),
  );
}
