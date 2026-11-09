import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class VideoTrimBar extends StatefulWidget {
  const VideoTrimBar({
    super.key,
    required this.thumbs,
    required this.durationMs,
    required this.startMs,
    required this.endMs,
    required this.positionMs,
    required this.onChanged,
    required this.onChangeEnd,
    this.minMs = 1000,
    this.maxMs,
  });

  final List<File> thumbs;
  final int durationMs;
  final int startMs;
  final int endMs;
  final int positionMs;
  final int minMs;
  final int? maxMs;
  final void Function(int start, int end) onChanged;
  final void Function(int start, int end) onChangeEnd;

  @override
  State<VideoTrimBar> createState() => _VideoTrimBarState();
}

class _VideoTrimBarState extends State<VideoTrimBar> {
  static const handleW = 16.0;
  int? _drag; // 0 = start, 1 = end
  late int _s = widget.startMs;
  late int _e = widget.endMs;

  @override
  void didUpdateWidget(covariant VideoTrimBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_drag == null) {
      _s = widget.startMs;
      _e = widget.endMs;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.durationMs <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        double px(int ms) => (ms / widget.durationMs * w).clamp(0.0, w);
        int ms(double dx) => (dx / w * widget.durationMs).round();

        return GestureDetector(
          onHorizontalDragStart: (d) {
            final x = d.localPosition.dx;
            _drag = (x - px(_s)).abs() < (x - px(_e)).abs() ? 0 : 1;
          },
          onHorizontalDragUpdate: (d) {
            final delta = ms(d.delta.dx);
            setState(() {
              if (_drag == 0) {
                _s = (_s + delta).clamp(0, _e - widget.minMs);
              } else {
                _e = (_e + delta).clamp(_s + widget.minMs, widget.durationMs);
              }
              if (widget.maxMs != null && _e - _s > widget.maxMs!) {
                if (_drag == 0) {
                  _s = _e - widget.maxMs!;
                } else {
                  _e = _s + widget.maxMs!;
                }
              }
            });
            widget.onChanged(_s, _e);
          },
          onHorizontalDragEnd: (_) {
            _drag = null;
            widget.onChangeEnd(_s, _e);
          },
          child: SizedBox(
            height: 56,
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.thumbs.isNotEmpty
                      ? Row(
                          children: [
                            for (final f in widget.thumbs)
                              Expanded(
                                child: Image.file(
                                  f,
                                  fit: BoxFit.cover,
                                  height: 56,
                                  errorBuilder: (_, _, _) => ColoredBox(
                                    color: context.surfaceHighColor,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(color: context.surfaceHighColor),
                ),
                // Áreas descartadas escurecidas
                Positioned(
                  left: 0,
                  width: px(_s),
                  top: 0,
                  bottom: 0,
                  child: const ColoredBox(color: Color(0xAA000000)),
                ),
                Positioned(
                  left: px(_e),
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: const ColoredBox(color: Color(0xAA000000)),
                ),
                // Moldura
                Positioned(
                  left: px(_s) - handleW / 2,
                  width: px(_e) - px(_s) + handleW,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.primary,
                        width: AppDepth.borderThick,
                      ),
                    ),
                  ),
                ),
                // Playhead
                Positioned(
                  left: px(widget.positionMs.clamp(_s, _e)) - 1,
                  width: 2,
                  top: -4,
                  bottom: -4,
                  child: ColoredBox(color: context.colors.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
