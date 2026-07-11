import 'package:flutter/material.dart';

/// Twitter-style scroll direction tracker: hides on scroll-down, reveals on
/// scroll-up, and always reveals at the top of the list.
///
/// Feed a bubbled [ScrollNotification] into [handleNotification] (always
/// returns false so the notification keeps bubbling up the tree), then drive
/// a [ScrollAwareBar] with [animation].
class HideOnScrollController {
  HideOnScrollController({required TickerProvider vsync, this.threshold = 12})
    : _controller = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 150),
        value: 1,
      );

  /// Minimum accumulated scroll delta (px) before toggling visibility.
  /// Avoids jitter from tiny scroll bounces.
  final double threshold;

  final AnimationController _controller;
  double _accumulated = 0;

  Animation<double> get animation => _controller;

  bool handleNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;

    if (!metrics.hasContentDimensions || metrics.maxScrollExtent <= 0) {
      _show();
      return false;
    }

    if (metrics.pixels <= metrics.minScrollExtent) {
      _show();
      _accumulated = 0;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta == 0) return false;

      final sameDirection =
          (delta > 0 && _accumulated >= 0) || (delta < 0 && _accumulated <= 0);
      _accumulated = sameDirection ? _accumulated + delta : delta;

      if (_accumulated > threshold) {
        _hide();
        _accumulated = 0;
      } else if (_accumulated < -threshold) {
        _show();
        _accumulated = 0;
      }
    }

    return false;
  }

  void _show() {
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
    );
  }

  void _hide() {
    _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
    );
  }

  void dispose() {
    _controller.dispose();
  }
}

enum ScrollBarEdge { top, bottom }

/// Overlays [child] and translates it off-screen toward [edge] as
/// [animation] goes from 1 (visible) to 0 (hidden). Uses [Transform.translate]
/// (GPU-accelerated, no relayout) rather than a height/size animation.
class ScrollAwareBar extends StatelessWidget {
  const ScrollAwareBar({
    super.key,
    required this.animation,
    required this.height,
    required this.edge,
    required this.child,
  });

  final Animation<double> animation;
  final double height;
  final ScrollBarEdge edge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final hiddenOffset = height * (1 - animation.value);
        final dy = edge == ScrollBarEdge.bottom ? hiddenOffset : -hiddenOffset;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: RepaintBoundary(child: child),
    );
  }
}
