import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'editor_models.dart';

class CropGeometry {
  const CropGeometry(this.crop, this.imageSize);
  final CropState crop;
  final Size imageSize;

  Size get rotated => crop.quarterTurns.isOdd
      ? Size(imageSize.height, imageSize.width)
      : imageSize;
  Size get framePx =>
      Size(crop.rect.width * rotated.width, crop.rect.height * rotated.height);
  double get aspect => framePx.width / framePx.height;
  Offset get _centerOffset => Offset(
    (crop.rect.center.dx - .5) * rotated.width,
    (crop.rect.center.dy - .5) * rotated.height,
  );

  /// Zoom mínimo (>=1) para a moldura ficar 100% coberta pela imagem girada
  /// (straighten). θ=0 → 1.
  double get requiredZoom {
    final th = crop.straightenDeg * math.pi / 180;
    if (th == 0) return 1;
    final cs = math.cos(-th), sn = math.sin(-th);
    final hw = rotated.width / 2, hh = rotated.height / 2;
    final fw = framePx.width / 2, fh = framePx.height / 2;
    var s = 1.0;
    for (final f in [
      Offset(-fw, -fh),
      Offset(fw, -fh),
      Offset(fw, fh),
      Offset(-fw, fh),
    ]) {
      final q = Offset(f.dx * cs - f.dy * sn, f.dx * sn + f.dy * cs); // R(-θ)·f
      s = math.max(s, _need(q.dx, _centerOffset.dx, hw));
      s = math.max(s, _need(q.dy, _centerOffset.dy, hh));
    }
    return s;
  }

  double _need(double q, double c, double half) {
    final room = q > 0 ? half - c : half + c;
    return room <= 0 ? 1e6 : q.abs() / room;
  }

  /// Matriz que leva pixels da imagem original -> viewport (moldura na tela).
  Matrix4 matrixFor(Size viewport) {
    final k = viewport.width / framePx.width;
    return Matrix4.identity()
      ..translateByDouble(viewport.width / 2, viewport.height / 2, 0.0, 1.0)
      ..scaleByDouble(k, k, 1.0, 1.0)
      ..rotateZ(crop.straightenDeg * math.pi / 180)
      ..scaleByDouble(requiredZoom, requiredZoom, 1.0, 1.0)
      ..translateByDouble(-_centerOffset.dx, -_centerOffset.dy, 0.0, 1.0)
      ..rotateZ(crop.quarterTurns * math.pi / 2)
      ..scaleByDouble(crop.flipH ? -1.0 : 1.0, 1.0, 1.0, 1.0)
      ..translateByDouble(
        -imageSize.width / 2,
        -imageSize.height / 2,
        0.0,
        1.0,
      );
  }
}

/// Crop inicial com aspecto travado (ex.: 9/16 do story), centralizado.
Rect centeredAspectCrop(Size source, double? aspect) {
  if (aspect == null) return const Rect.fromLTWH(0, 0, 1, 1);
  final oriented = CropGeometry(const CropState(), source).rotated;
  final ratio = oriented.width / oriented.height;
  final width = ratio > aspect ? aspect / ratio : 1.0;
  final height = ratio > aspect ? 1.0 : ratio / aspect;
  return Rect.fromLTWH((1 - width) / 2, (1 - height) / 2, width, height);
}

/// Mantém a rect dentro de 0..1 do espaço rotacionado.
Rect clampCropRect(Rect r) {
  var dx = 0.0, dy = 0.0;
  if (r.left < 0) dx = -r.left;
  if (r.right > 1) dx = 1 - r.right;
  if (r.top < 0) dy = -r.top;
  if (r.bottom > 1) dy = 1 - r.bottom;
  return r.shift(Offset(dx, dy));
}

/// Resultado do remapeamento de camadas/traços após mudança de crop.
class CropRemap {
  const CropRemap(this.strokes, this.layers);
  final List<Stroke> strokes;
  final List<EditorLayer> layers;
}

/// Camadas e traços são normalizados 0..1 no canvas CROPADO. Quando o crop
/// muda, eles precisam ser re-mapeados para o novo frame — senão desalinham
/// do que o usuário viu. null quando nada muda de verdade.
CropRemap? remapEditsForCrop({
  required List<Stroke> strokes,
  required List<EditorLayer> layers,
  required CropState from,
  required CropState to,
  required Size source,
}) {
  if (from.rect == to.rect &&
      from.quarterTurns == to.quarterTurns &&
      from.flipH == to.flipH) {
    return null;
  }
  final gFrom = CropGeometry(from, source);
  final gTo = CropGeometry(to, source);
  final widthRatio = gFrom.framePx.width / gTo.framePx.width;

  Offset mapPoint(Offset p) {
    // canvas (frame antigo) -> espaço rotacionado antigo
    final r = Offset(
      (from.rect.left + p.dx * from.rect.width) * gFrom.rotated.width,
      (from.rect.top + p.dy * from.rect.height) * gFrom.rotated.height,
    );
    // desfaz flip e quarter-turns -> pixels da imagem original
    var c = r - Offset(gFrom.rotated.width / 2, gFrom.rotated.height / 2);
    c = _rot(c, -from.quarterTurns * math.pi / 2);
    if (from.flipH) c = Offset(-c.dx, c.dy);
    // reaplica o estado novo
    if (to.flipH) c = Offset(-c.dx, c.dy);
    c = _rot(c, to.quarterTurns * math.pi / 2);
    final q = c + Offset(gTo.rotated.width / 2, gTo.rotated.height / 2);
    // espaço rotacionado novo -> canvas novo
    return Offset(
      (q.dx / gTo.rotated.width - to.rect.left) / to.rect.width,
      (q.dy / gTo.rotated.height - to.rect.top) / to.rect.height,
    );
  }

  final mappedStrokes = [
    for (final s in strokes)
      Stroke(
        kind: s.kind,
        points: [for (final p in s.points) mapPoint(p)],
        color: s.color,
        widthFactor: s.widthFactor * widthRatio,
      ),
  ];
  final mappedLayers = [
    for (final l in layers)
      switch (l) {
        TextLayer t =>
          t
              .copyWith(sizeFactor: t.sizeFactor * widthRatio)
              .withTransform(
                LayerTransform(
                  center: mapPoint(t.transform.center),
                  scale: t.transform.scale,
                  rotation: _mapRotation(t.transform.rotation, from, to),
                ),
              ),
        StickerLayer s =>
          s
              .copyWithSize(s.sizeFactor * widthRatio)
              .withTransform(
                LayerTransform(
                  center: mapPoint(s.transform.center),
                  scale: s.transform.scale,
                  rotation: _mapRotation(s.transform.rotation, from, to),
                ),
              ),
      },
  ];
  return CropRemap(mappedStrokes, mappedLayers);
}

// ponytail: conteúdo de texto/sticker não é espelhado no flip (só posição e
// rotação seguem) — mantém o texto legível; espelhar conteúdo se o owner pedir.
double _mapRotation(double rotation, CropState from, CropState to) {
  var v = rotation;
  if (from.flipH != to.flipH) v = -v;
  return v + (to.quarterTurns - from.quarterTurns) * math.pi / 2;
}

Offset _rot(Offset c, double ang) => Offset(
  c.dx * math.cos(ang) - c.dy * math.sin(ang),
  c.dx * math.sin(ang) + c.dy * math.cos(ang),
);
