import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

/// Animated typing indicator shown when the other user is typing.
///
/// Displays three square dots that fade in/out in a staggered pattern.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.enter)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return _Dot(animation: _ctrl, index: i);
        }),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Animation<double> animation;
  final int index;

  const _Dot({required this.animation, required this.index});

  @override
  Widget build(BuildContext context) {
    // Each dot is offset by 300ms (staggered)
    final begin = index * 0.3;
    final end = begin + 0.5;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = AppMotion.enterCurve.transform(
          animation.value >= begin && animation.value <= end
              ? ((animation.value - begin) / (end - begin))
              : animation.value < begin
              ? 0.0
              : 1.0,
        );
        // Convert linear pulse to a smooth in-out for fade effect
        final opacity = value <= 0.5 ? value * 2 : (1 - value) * 2;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
