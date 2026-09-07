import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class AuthStagger extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double begin;
  final double end;
  final Animation<double>? opacity;
  final Animation<Offset>? slide;

  const AuthStagger({
    super.key,
    required this.child,
    required this.animation,
    required this.begin,
    required this.end,
  }) : opacity = null,
       slide = null;

  const AuthStagger.fromAnimations({
    super.key,
    required this.child,
    required this.opacity,
    required this.slide,
  }) : animation = kAlwaysCompleteAnimation,
       begin = 0,
       end = 1;

  @override
  Widget build(BuildContext context) {
    final curve =
        opacity ??
        CurvedAnimation(
          parent: animation,
          curve: Interval(begin, end, curve: AppMotion.enterCurve),
        );
    final position =
        slide ??
        Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve);

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(position: position, child: child),
    );
  }
}
