import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

import '../../domain/crop_geometry.dart';
import '../../domain/editor_models.dart';

/// Moldura fixa + imagem se move (pan/pinch). `onChanged` ao vivo (local),
/// `onCommit` no fim de cada gesto (vira uma entrada de undo).
class CropCanvas extends StatefulWidget {
  const CropCanvas({
    super.key,
    required this.image,
    required this.crop,
    required this.onChanged,
    required this.onCommit,
    this.circular = false,
  });
  final ui.Image image;
  final CropState crop;
  final ValueChanged<CropState> onChanged;
  final ValueChanged<CropState> onCommit;
  final bool circular;

  @override
  State<CropCanvas> createState() => _CropCanvasState();
}

class _CropCanvasState extends State<CropCanvas> {
  double _lastScale = 1;
  late CropState _crop = widget.crop;

  @override
  void didUpdateWidget(covariant CropCanvas old) {
    super.didUpdateWidget(old);
    if (old.crop != widget.crop) _crop = widget.crop;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) {
      final source = Size(
        widget.image.width.toDouble(),
        widget.image.height.toDouble(),
      );
      final geometry = CropGeometry(_crop, source);
      final frame = applyBoxFit(
        BoxFit.contain,
        geometry.framePx,
        const EdgeInsets.all(Spacing.lg).deflateSize(box.biggest),
      ).destination;
      // px de tela por px da imagem (com zoom do straighten)
      final screenPerImage =
          frame.width / geometry.framePx.width / geometry.requiredZoom;

      return Center(
        child: SizedBox.fromSize(
          size: frame,
          child: GestureDetector(
            onScaleStart: (_) => _lastScale = 1,
            onScaleUpdate: (details) {
              // PAN: move a imagem sob a moldura => move a rect no sentido
              // oposto (no espaço pré-straighten)
              final th = _crop.straightenDeg * math.pi / 180;
              final screen = Offset(
                details.focalPointDelta.dx,
                details.focalPointDelta.dy,
              );
              final imageDelta =
                  Offset(
                    screen.dx * math.cos(-th) - screen.dy * math.sin(-th),
                    screen.dx * math.sin(-th) + screen.dy * math.cos(-th),
                  ) /
                  screenPerImage;
              var rect = _crop.rect.shift(
                Offset(
                  -imageDelta.dx / geometry.rotated.width,
                  -imageDelta.dy / geometry.rotated.height,
                ),
              );
              // PINCH: zoom in = rect menor
              final zoom = details.scale / _lastScale;
              _lastScale = details.scale;
              rect = Rect.fromCenter(
                center: rect.center,
                width: (rect.width / zoom).clamp(.05, 1),
                height: (rect.height / zoom).clamp(.05, 1),
              );
              setState(() => _crop = _crop.copyWith(rect: clampCropRect(rect)));
              widget.onChanged(_crop);
            },
            onScaleEnd: (_) => widget.onCommit(_crop),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Transform(
                  transform: geometry.matrixFor(frame),
                  alignment: Alignment.topLeft,
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: source.width,
                    maxHeight: source.height,
                    child: SizedBox.fromSize(
                      size: source,
                      child: RawImage(image: widget.image, fit: BoxFit.fill),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ScrimGridPainter(circular: widget.circular),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ScrimGridPainter extends CustomPainter {
  const _ScrimGridPainter({this.circular = false});
  final bool circular;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Offset.zero & size;
    final hole = Path();
    if (circular) {
      hole.addOval(frame);
    } else {
      hole.addRect(frame);
    }
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(frame.inflate(4000)),
      hole,
    );
    canvas.drawPath(scrim, Paint()..color = const Color(0xB3000000));
    if (!circular) {
      final grid = Paint()
        ..color = AppColors.white.withAlpha(138)
        ..strokeWidth = .8;
      for (var i = 1; i < 3; i++) {
        canvas.drawLine(
          Offset(size.width * i / 3, 0),
          Offset(size.width * i / 3, size.height),
          grid,
        );
        canvas.drawLine(
          Offset(0, size.height * i / 3),
          Offset(size.width, size.height * i / 3),
          grid,
        );
      }
      canvas.drawRect(
        frame,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.white
          ..strokeWidth = 2,
      );
    } else {
      canvas.drawOval(
        frame,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.white
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimGridPainter old) => old.circular != circular;
}
