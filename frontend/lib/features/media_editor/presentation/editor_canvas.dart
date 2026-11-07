import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../application/editor_controller.dart';
import '../domain/color_math.dart';
import '../domain/crop_geometry.dart';
import '../domain/editor_models.dart';
import '../domain/filter_presets.dart';
import 'layer_item.dart';
import 'widgets/editor_paint.dart';

/// Preview WYSIWYG. Ordem (de baixo pra cima):
/// 1. base (imagem ou vídeo) com matriz de crop + ColorFiltered (filtro/ajustes) + blur
/// 2. RepaintBoundary do overlay (exportKey = tudo; overlayKey = só overlay,
///    usado pelo export de vídeo na Fase 2): vinheta → desenho → camadas
/// 3. lixeira FORA do boundary de export
class EditorCanvas extends ConsumerStatefulWidget {
  const EditorCanvas({
    super.key,
    required this.sessionId,
    required this.exportKey,
    required this.overlayKey,
    this.image,
    this.video,
    required this.liveStroke,
    this.interactive = true,
    this.liveAdjustments,
    this.onStrokeStart,
    this.onStrokeUpdate,
    this.onStrokeEnd,
    this.onLayerEdit,
  });
  final String sessionId;
  final GlobalKey exportKey;
  final GlobalKey overlayKey;
  final ui.Image? image;
  final VideoPlayerController? video;

  /// Traço em andamento (desenho) — comitado pelo controller no fim do gesto.
  final ValueNotifier<Stroke?> liveStroke;

  /// Delta de ajuste ao vivo (slider) — comitado via setAdjustments.
  final ValueListenable<Adjustments?>? liveAdjustments;

  /// false enquanto desenho/crop tomam o gesto do canvas.
  final bool interactive;
  final ValueChanged<Offset>? onStrokeStart, onStrokeUpdate;
  final VoidCallback? onStrokeEnd;
  final ValueChanged<EditorLayer>? onLayerEdit;

  @override
  ConsumerState<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends ConsumerState<EditorCanvas> {
  final _trashKey = GlobalKey();
  final _showTrash = ValueNotifier(false);
  final _overTrash = ValueNotifier(false);

  @override
  void dispose() {
    _showTrash.dispose();
    _overTrash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(editorControllerProvider(widget.sessionId));
    final state = history.present;
    if (widget.image == null && widget.video == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    final geometry = CropGeometry(state.crop, state.sourceSize);

    return LayoutBuilder(
      builder: (context, box) {
        final viewport = applyBoxFit(
          BoxFit.contain,
          geometry.framePx,
          box.biggest,
        ).destination;
        final matrix = geometry.matrixFor(viewport);

        Widget canvas = RepaintBoundary(
          key: widget.exportKey,
          child: SizedBox.fromSize(
            size: viewport,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildColorFiltered(state, matrix),
                  RepaintBoundary(
                    key: widget.overlayKey,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        _buildVignette(state),
                        _buildDrawing(state.strokes),
                        for (final layer in state.layers)
                          LayerItem(
                            key: ValueKey(layer.id),
                            layer: layer,
                            canvasSize: viewport,
                            selected:
                                history.selectedLayerId == layer.id &&
                                widget.interactive,
                            interactive: widget.interactive,
                            onSelect: () => ref
                                .read(
                                  editorControllerProvider(
                                    widget.sessionId,
                                  ).notifier,
                                )
                                .bringToFront(layer.id),
                            onEdit: () => widget.onLayerEdit?.call(layer),
                            onDragging: _onDrag,
                            onCommit: (transform) => ref
                                .read(
                                  editorControllerProvider(
                                    widget.sessionId,
                                  ).notifier,
                                )
                                .updateLayer(layer.withTransform(transform)),
                            onDelete: () => ref
                                .read(
                                  editorControllerProvider(
                                    widget.sessionId,
                                  ).notifier,
                                )
                                .removeLayer(layer.id),
                            isOverTrash: () => _overTrash.value,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final drawing = widget.onStrokeStart != null;
        if (drawing) {
          canvas = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) =>
                widget.onStrokeStart!(_normalize(d.localPosition, viewport)),
            onPanUpdate: (d) =>
                widget.onStrokeUpdate!(_normalize(d.localPosition, viewport)),
            onPanEnd: (_) => widget.onStrokeEnd?.call(),
            child: canvas,
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            canvas,
            // lixeira fica FORA do boundary de export
            Positioned(
              bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
              child: ValueListenableBuilder<bool>(
                valueListenable: _showTrash,
                builder: (_, show, _) => AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _overTrash,
                    builder: (_, over, _) => Container(
                      key: _trashKey,
                      width: over ? 64 : 52,
                      height: over ? 64 : 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: over ? Colors.red : Colors.black54,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Offset _normalize(Offset local, Size viewport) =>
      Offset(local.dx / viewport.width, local.dy / viewport.height);

  Widget _buildColorFiltered(EditorState state, Matrix4 matrix) {
    final blurStrokes = state.strokes
        .where((s) => s.kind == StrokeKind.blur)
        .toList();
    final mediaContent = widget.image != null
        ? RawImage(image: widget.image, fit: BoxFit.fill)
        : (widget.video != null
              ? VideoPlayer(widget.video!)
              : const SizedBox.shrink());

    final content = Stack(
      fit: StackFit.expand,
      children: [
        Transform(
          transform: matrix,
          alignment: Alignment.topLeft,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: state.sourceSize.width,
            maxHeight: state.sourceSize.height,
            child: SizedBox.fromSize(
              size: state.sourceSize,
              child: mediaContent,
            ),
          ),
        ),
        if (blurStrokes.isNotEmpty && widget.image != null)
          CustomPaint(
            painter: BlurStrokesPainter(
              image: widget.image!,
              matrix: matrix,
              strokes: blurStrokes,
            ),
          ),
      ],
    );
    final live = widget.liveAdjustments;
    if (live == null) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(
          adjustmentsToMatrix(effectiveAdjustments(state)),
        ),
        child: content,
      );
    }
    return ValueListenableBuilder<Adjustments?>(
      valueListenable: live,
      builder: (_, delta, _) {
        final base = effectiveAdjustments(state);
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(
            adjustmentsToMatrix(delta == null ? base : base.plus(delta)),
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildVignette(EditorState state) {
    final live = widget.liveAdjustments;
    if (live == null) return _vignetteFor(effectiveAdjustments(state));
    return ValueListenableBuilder<Adjustments?>(
      valueListenable: live,
      builder: (_, delta, _) => _vignetteFor(
        delta == null
            ? effectiveAdjustments(state)
            : effectiveAdjustments(state).plus(delta),
      ),
    );
  }

  Widget _vignetteFor(Adjustments adjustments) => adjustments.vignette > 0
      ? IgnorePointer(child: VignetteOverlay(strength: adjustments.vignette))
      : const SizedBox.shrink();

  Widget _buildDrawing(List<Stroke> strokes) => Positioned.fill(
    child: IgnorePointer(
      child: ValueListenableBuilder<Stroke?>(
        valueListenable: widget.liveStroke,
        builder: (_, live, _) => CustomPaint(
          size: Size.infinite,
          painter: DrawingPainter(strokes: strokes, live: live),
        ),
      ),
    ),
  );

  void _onDrag(Offset global, bool dragging) {
    _showTrash.value = dragging;
    if (!dragging) {
      _overTrash.value = false;
      return;
    }
    final box = _trashKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final over = rect.inflate(24).contains(global);
    if (over != _overTrash.value) {
      _overTrash.value = over;
      if (over) HapticFeedback.selectionClick();
    }
  }
}
