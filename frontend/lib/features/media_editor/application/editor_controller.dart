import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/crop_geometry.dart';
import '../domain/editor_models.dart';
import 'editor_config.dart';

part 'editor_controller.g.dart';

class EditorArgs {
  const EditorArgs({
    required this.sessionId,
    required this.initial,
    required this.config,
  });
  final String sessionId;
  final EditorState initial;
  final EditorConfig config;

  @override
  bool operator ==(Object other) =>
      other is EditorArgs && other.sessionId == sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

class EditorHistory {
  EditorHistory(List<EditorState> entries, this.index, {this.selectedLayerId})
    : entries = List.unmodifiable(entries);
  final List<EditorState> entries;
  final int index;

  /// Camada selecionada (id) — seleção não entra no histórico.
  final String? selectedLayerId;

  EditorState get present => entries[index];
  bool get canUndo => index > 0;
  bool get canRedo => index < entries.length - 1;

  /// Legenda não entra no histórico; conta como mudança para o descarte.
  bool get hasChanges => index > 0 || present.caption.isNotEmpty;
}

@riverpod
class EditorController extends _$EditorController {
  static const _maxHistory = 50;

  @override
  EditorHistory build(String sessionId) => EditorHistory([EditorState()], 0);

  /// Chamado pela página após decodificar a imagem (tamanho real conhecido).
  void initialize(EditorState initial) => state = EditorHistory([initial], 0);

  /// Todo commit passa por aqui: empilha histórico e descarta o redo.
  void commit(EditorState next, {String? select}) {
    if (identical(state.present, next)) return;
    final entries = [...state.entries.take(state.index + 1), next];
    if (entries.length > _maxHistory) entries.removeAt(0);
    state = EditorHistory(
      entries,
      entries.length - 1,
      selectedLayerId: select ?? state.selectedLayerId,
    );
  }

  void undo() {
    if (state.canUndo) {
      state = EditorHistory(
        state.entries,
        state.index - 1,
        selectedLayerId: state.selectedLayerId,
      );
    }
  }

  void redo() {
    if (state.canRedo) {
      state = EditorHistory(
        state.entries,
        state.index + 1,
        selectedLayerId: state.selectedLayerId,
      );
    }
  }

  // ---- camadas

  void addLayer(EditorLayer layer) => commit(
    state.present.copyWith(layers: [...state.present.layers, layer]),
    select: layer.id,
  );

  void updateLayer(EditorLayer layer) => commit(
    state.present.copyWith(
      layers: [
        for (final l in state.present.layers)
          if (l.id == layer.id) layer else l,
      ],
    ),
  );

  void removeLayer(String id) {
    commit(
      state.present.copyWith(
        layers: state.present.layers.where((l) => l.id != id).toList(),
      ),
    );
    select(null);
  }

  void bringToFront(String id) {
    final layers = state.present.layers;
    final i = layers.indexWhere((l) => l.id == id);
    if (i < 0 || i == layers.length - 1) return;
    final item = layers[i];
    final reordered = [...layers.take(i), ...layers.skip(i + 1), item];
    commit(state.present.copyWith(layers: reordered));
  }

  void select(String? id) =>
      state = EditorHistory(state.entries, state.index, selectedLayerId: id);

  // ---- desenho

  void addStroke(Stroke stroke) => commit(
    state.present.copyWith(strokes: [...state.present.strokes, stroke]),
  );

  // ---- crop. Todo caminho passa por setCrop: é o choke point do remapeamento
  // de camadas/traços (coords normalizadas no canvas cropado).

  void setCrop(CropState crop) {
    final cur = state.present;
    final remap = remapEditsForCrop(
      strokes: cur.strokes,
      layers: cur.layers,
      from: cur.crop,
      to: crop,
      source: cur.sourceSize,
    );
    commit(
      cur.copyWith(crop: crop, strokes: remap?.strokes, layers: remap?.layers),
    );
  }

  void rotate90() {
    final c = state.present.crop;
    final r = c.rect;
    setCrop(
      c.copyWith(
        quarterTurns: (c.quarterTurns + 1) % 4,
        rect: Rect.fromLTRB(1 - r.bottom, r.left, 1 - r.top, r.right),
        lockedAspect: c.lockedAspect == null ? null : 1 / c.lockedAspect!,
      ),
    );
  }

  void flip() {
    final c = state.present.crop;
    final r = c.rect;
    setCrop(
      c.copyWith(
        flipH: !c.flipH,
        rect: Rect.fromLTRB(1 - r.right, r.top, 1 - r.left, r.bottom),
      ),
    );
  }

  /// [ratio] = w/h em px finais (1, 4/5, 16/9, 9/16); null = livre.
  void setAspect(double? ratio) {
    final c = state.present.crop;
    if (ratio == null) {
      setCrop(c.copyWith(clearAspect: true));
      return;
    }
    final g = CropGeometry(c, state.present.sourceSize);
    final rot = g.rotated;
    var w = c.rect.width * rot.width, h = c.rect.height * rot.height;
    if (w / h > ratio) {
      w = h * ratio;
    } else {
      h = w / ratio;
    }
    final next = Rect.fromCenter(
      center: c.rect.center,
      width: w / rot.width,
      height: h / rot.height,
    );
    setCrop(c.copyWith(rect: clampCropRect(next), lockedAspect: ratio));
  }

  void setStraighten(double deg) =>
      setCrop(state.present.crop.copyWith(straightenDeg: deg.clamp(-45, 45)));

  // ---- cor

  void setFilter(String id, {double intensity = 1}) =>
      commit(state.present.copyWith(filterId: id, filterIntensity: intensity));

  void setAdjustments(Adjustments adjustments) =>
      commit(state.present.copyWith(adjustments: adjustments));

  void setVideo(VideoEdits video) =>
      commit(state.present.copyWith(video: video));

  // ---- sem histórico (legenda/toggles não poluem undo)

  void setCaption(String caption) =>
      _replacePresent(state.present.copyWith(caption: caption));

  void setViewOnce(bool viewOnce) =>
      _replacePresent(state.present.copyWith(viewOnce: viewOnce));

  void setHd(bool hd) => _replacePresent(state.present.copyWith(hd: hd));

  void _replacePresent(EditorState present) {
    final entries = [...state.entries];
    entries[state.index] = present;
    state = EditorHistory(
      entries,
      state.index,
      selectedLayerId: state.selectedLayerId,
    );
  }
}
