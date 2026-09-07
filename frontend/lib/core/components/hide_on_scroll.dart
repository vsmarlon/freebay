import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:flutter/material.dart';

class HideOnScrollController {
  HideOnScrollController({required TickerProvider vsync, this.threshold = 12})
    : _controller = AnimationController(
        vsync: vsync,
        duration: AppMotion.base,
        value: 1,
      );

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
    _controller.animateTo(1, duration: AppMotion.base);
  }

  void _hide() {
    _controller.animateTo(0, duration: AppMotion.base);
  }

  void dispose() {
    _controller.dispose();
  }
}

enum ScrollBarEdge { top, bottom }

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
