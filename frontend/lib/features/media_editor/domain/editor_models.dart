import 'dart:ui';

/// Tipo da mídia em edição. Vídeo entra no mesmo modelo na Fase 2.
enum MediaKind { image, video }

enum TextBg { none, solid, translucent }

enum StickerKind { emoji, price, sold, location, link }

enum StrokeKind { pen, marker, neon, eraser, blur }

/// Transformação de uma camada, normalizada 0..1 no canvas (já cropado).
class LayerTransform {
  const LayerTransform({
    this.center = const Offset(.5, .5),
    this.scale = 1,
    this.rotation = 0,
  });
  final Offset center;
  final double scale;
  final double rotation; // radianos
  LayerTransform copyWith({Offset? center, double? scale, double? rotation}) =>
      LayerTransform(
        center: center ?? this.center,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
      );
}

sealed class EditorLayer {
  const EditorLayer({
    required this.id,
    this.transform = const LayerTransform(),
  });
  final String id;
  final LayerTransform transform;
  EditorLayer withTransform(LayerTransform transform);
}

class TextLayer extends EditorLayer {
  const TextLayer({
    required super.id,
    super.transform,
    required this.text,
    this.font = 'SpaceGrotesk',
    this.color = const Color(0xFFFFFFFF),
    this.bg = TextBg.none,
    this.align = TextAlign.center,
    this.sizeFactor = .08,
  });
  final String text, font;
  final Color color;
  final TextBg bg;
  final TextAlign align;

  /// fontSize = canvasWidth * sizeFactor — escala com a resolução do export.
  final double sizeFactor;

  TextLayer copyWith({
    String? text,
    String? font,
    Color? color,
    TextBg? bg,
    TextAlign? align,
    double? sizeFactor,
  }) => TextLayer(
    id: id,
    transform: transform,
    text: text ?? this.text,
    font: font ?? this.font,
    color: color ?? this.color,
    bg: bg ?? this.bg,
    align: align ?? this.align,
    sizeFactor: sizeFactor ?? this.sizeFactor,
  );

  @override
  TextLayer withTransform(LayerTransform transform) => TextLayer(
    id: id,
    transform: transform,
    text: text,
    font: font,
    color: color,
    bg: bg,
    align: align,
    sizeFactor: sizeFactor,
  );
}

class StickerLayer extends EditorLayer {
  const StickerLayer({
    required super.id,
    super.transform,
    required this.kind,
    required this.payload,
    this.sizeFactor = .18,
  });
  final StickerKind kind;

  /// emoji | "R$ 199,90" | "Porto Alegre" | url/listingId
  final String payload;
  final double sizeFactor;

  StickerLayer copyWithSize(double sizeFactor) => StickerLayer(
    id: id,
    transform: transform,
    kind: kind,
    payload: payload,
    sizeFactor: sizeFactor,
  );

  @override
  StickerLayer withTransform(LayerTransform transform) => StickerLayer(
    id: id,
    transform: transform,
    kind: kind,
    payload: payload,
    sizeFactor: sizeFactor,
  );
}

class Stroke {
  Stroke({
    required this.kind,
    required List<Offset> points,
    required this.color,
    required this.widthFactor,
  }) : points = List.unmodifiable(points);
  final StrokeKind kind;
  final List<Offset> points; // 0..1 no canvas
  final Color color;

  /// largura = canvasWidth * widthFactor
  final double widthFactor;
}

class Adjustments {
  const Adjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.fade = 0,
    this.vignette = 0,
  });
  final double brightness, contrast, saturation, warmth; // -1..1
  final double fade, vignette; // 0..1

  Adjustments scaled(double k) => Adjustments(
    brightness: brightness * k,
    contrast: contrast * k,
    saturation: saturation * k,
    warmth: warmth * k,
    fade: fade * k,
    vignette: vignette * k,
  );

  Adjustments plus(Adjustments o) => Adjustments(
    brightness: brightness + o.brightness,
    contrast: contrast + o.contrast,
    saturation: saturation + o.saturation,
    warmth: warmth + o.warmth,
    fade: fade + o.fade,
    vignette: vignette + o.vignette,
  );

  Adjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? fade,
    double? vignette,
  }) => Adjustments(
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    warmth: warmth ?? this.warmth,
    fade: fade ?? this.fade,
    vignette: vignette ?? this.vignette,
  );
}

class CropState {
  const CropState({
    this.rect = const Rect.fromLTWH(0, 0, 1, 1),
    this.quarterTurns = 0,
    this.flipH = false,
    this.straightenDeg = 0,
    this.lockedAspect,
  });
  // Coordinates refer to the source after quarter-turns and horizontal flip.
  final Rect rect;
  final int quarterTurns;
  final bool flipH;
  final double straightenDeg;
  final double? lockedAspect; // largura/altura em px finais; null = livre

  CropState copyWith({
    Rect? rect,
    int? quarterTurns,
    bool? flipH,
    double? straightenDeg,
    double? lockedAspect,
    bool clearAspect = false,
  }) => CropState(
    rect: rect ?? this.rect,
    quarterTurns: quarterTurns ?? this.quarterTurns,
    flipH: flipH ?? this.flipH,
    straightenDeg: straightenDeg ?? this.straightenDeg,
    lockedAspect: clearAspect ? null : lockedAspect ?? this.lockedAspect,
  );
}

class VideoEdits {
  const VideoEdits({
    required this.durationMs,
    this.trimStartMs = 0,
    int? trimEndMs,
    this.muted = false,
    this.speed = 1,
    this.coverMs = 0,
  }) : trimEndMs = trimEndMs ?? durationMs;
  final int durationMs, trimStartMs, trimEndMs, coverMs;
  final bool muted;
  final double speed;
  int get trimmedMs => trimEndMs - trimStartMs;

  VideoEdits copyWith({
    int? trimStartMs,
    int? trimEndMs,
    bool? muted,
    double? speed,
    int? coverMs,
  }) => VideoEdits(
    durationMs: durationMs,
    trimStartMs: trimStartMs ?? this.trimStartMs,
    trimEndMs: trimEndMs ?? this.trimEndMs,
    muted: muted ?? this.muted,
    speed: speed ?? this.speed,
    coverMs: coverMs ?? this.coverMs,
  );
}

/// Estado completo de um item em edição. Tudo normalizado → o mesmo estado
/// exporta em qualquer resolução e é serializável (rascunho P2).
class EditorState {
  EditorState({
    this.kind = MediaKind.image,
    this.sourcePath,
    this.sourceSize = Size.zero,
    this.crop = const CropState(),
    this.adjustments = const Adjustments(),
    this.filterId = 'none',
    this.filterIntensity = 1,
    List<Stroke> strokes = const [],
    List<EditorLayer> layers = const [],
    this.video,
    this.caption = '',
    this.hd = false,
    this.viewOnce = false,
    this.altText,
  }) : strokes = List.unmodifiable(strokes),
       layers = List.unmodifiable(layers);
  final MediaKind kind;

  /// null quando a origem é memória (bytes diretos).
  final String? sourcePath;

  /// px, já com rotação de metadata aplicada (tamanho "de exibição").
  final Size sourceSize;
  final CropState crop;
  final Adjustments adjustments;
  final String filterId;
  final double filterIntensity;
  final List<Stroke> strokes;
  final List<EditorLayer> layers;
  final VideoEdits? video;
  final String caption;
  final bool hd, viewOnce;
  final String? altText;

  EditorState copyWith({
    MediaKind? kind,
    String? sourcePath,
    Size? sourceSize,
    CropState? crop,
    Adjustments? adjustments,
    String? filterId,
    double? filterIntensity,
    List<Stroke>? strokes,
    List<EditorLayer>? layers,
    VideoEdits? video,
    String? caption,
    bool? hd,
    bool? viewOnce,
    String? altText,
  }) => EditorState(
    kind: kind ?? this.kind,
    sourcePath: sourcePath ?? this.sourcePath,
    sourceSize: sourceSize ?? this.sourceSize,
    crop: crop ?? this.crop,
    adjustments: adjustments ?? this.adjustments,
    filterId: filterId ?? this.filterId,
    filterIntensity: filterIntensity ?? this.filterIntensity,
    strokes: strokes ?? this.strokes,
    layers: layers ?? this.layers,
    video: video ?? this.video,
    caption: caption ?? this.caption,
    hd: hd ?? this.hd,
    viewOnce: viewOnce ?? this.viewOnce,
    altText: altText ?? this.altText,
  );
}
