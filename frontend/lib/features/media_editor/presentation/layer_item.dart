import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/ui.dart';

import '../domain/editor_models.dart';
import 'widgets/layer_views.dart';

/// Camada interativa: um único gesto faz pan + pinch + rotate ao vivo via
/// ValueNotifier (sem rebuild do canvas); comita no fim do gesto. Arrastar
/// para a lixeira remove. Snap no centro com histerese + haptic.
class LayerItem extends StatefulWidget {
  const LayerItem({
    super.key,
    required this.layer,
    required this.canvasSize,
    required this.selected,
    required this.interactive,
    required this.onSelect,
    required this.onDragging,
    required this.onCommit,
    required this.onDelete,
    required this.isOverTrash,
    this.onEdit,
  });
  final EditorLayer layer;
  final Size canvasSize;
  final bool selected, interactive;
  final VoidCallback onSelect, onDelete;
  final void Function(Offset global, bool dragging) onDragging;
  final void Function(LayerTransform) onCommit;
  final bool Function() isOverTrash;
  final VoidCallback? onEdit;

  @override
  State<LayerItem> createState() => _LayerItemState();
}

class _LayerItemState extends State<LayerItem> {
  late final ValueNotifier<LayerTransform> _live = ValueNotifier(
    widget.layer.transform,
  );
  late LayerTransform _start;
  bool _snappedX = false, _snappedY = false;

  @override
  void didUpdateWidget(covariant LayerItem old) {
    super.didUpdateWidget(old);
    if (old.layer.transform != widget.layer.transform) {
      _live.value = widget.layer.transform;
    }
  }

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.canvasSize.width, h = widget.canvasSize.height;
    return ValueListenableBuilder<LayerTransform>(
      valueListenable: _live,
      builder: (_, t, child) => Positioned(
        left: t.center.dx * w,
        top: t.center.dy * h,
        child: FractionalTranslation(
          translation: const Offset(-.5, -.5),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateZ(t.rotation)
              ..scaleByDouble(t.scale, t.scale, 1.0, 1.0),
            child: child,
          ),
        ),
      ),
      child: widget.interactive
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onSelect,
              onDoubleTap: widget.onEdit,
              onScaleStart: (details) {
                _start = _live.value;
                widget.onSelect();
              },
              onScaleUpdate: (details) {
                // um único gesto: pan + pinch + rotate (delta incremental)
                var center =
                    _live.value.center +
                    Offset(
                      details.focalPointDelta.dx / w,
                      details.focalPointDelta.dy / h,
                    );
                // snap no centro (com histerese) + haptic
                const snap = .012;
                final nearX = (center.dx - .5).abs() < snap,
                    nearY = (center.dy - .5).abs() < snap;
                if (nearX) center = Offset(.5, center.dy);
                if (nearY) center = Offset(center.dx, .5);
                if ((nearX && !_snappedX) || (nearY && !_snappedY)) {
                  HapticFeedback.lightImpact();
                }
                _snappedX = nearX;
                _snappedY = nearY;

                _live.value = LayerTransform(
                  center: center,
                  scale: (_start.scale * details.scale).clamp(.3, 8.0),
                  rotation: _start.rotation + details.rotation,
                );
                widget.onDragging(details.focalPoint, true);
              },
              onScaleEnd: (_) {
                final delete = widget.isOverTrash();
                widget.onDragging(Offset.zero, false);
                if (delete) {
                  widget.onDelete();
                  return;
                }
                widget.onCommit(_live.value);
              },
              child: _selectionChrome(widget.selected, _layerContent()),
            )
          : _layerContent(),
    );
  }

  Widget _layerContent() => Padding(
    // amplia a área tocável de textos pequenos
    padding: const EdgeInsets.all(Spacing.md),
    child: switch (widget.layer) {
      TextLayer l => TextLayerView(
        layer: l,
        canvasWidth: widget.canvasSize.width,
      ),
      StickerLayer l => StickerLayerView(
        layer: l,
        canvasWidth: widget.canvasSize.width,
      ),
    },
  );

  Widget _selectionChrome(bool selected, Widget child) => selected
      ? DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: AppColors.white)),
          child: child,
        )
      : child;
}
