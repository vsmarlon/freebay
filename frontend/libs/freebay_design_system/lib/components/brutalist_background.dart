import 'dart:math' as math;
import 'package:flutter/material.dart';

class BrutalistBackground extends StatefulWidget {
  final Widget child;
  final bool? forceDark;

  const BrutalistBackground({
    required this.child,
    this.forceDark,
    super.key,
  });

  @override
  State<BrutalistBackground> createState() => _BrutalistBackgroundState();
}

class _BrutalistBackgroundState extends State<BrutalistBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.forceDark ??
        (Theme.of(context).brightness == Brightness.dark);

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AuroraBackgroundPainter(
                    animationValue: _controller.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _AuroraBackgroundPainter({
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Gradient
    final Rect rect = Offset.zero & size;
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF07000C),
                const Color(0xFF0A0D16),
                const Color(0xFF140818),
                const Color(0xFF05060A),
              ]
            : [
                const Color(0xFFF9FAFB),
                const Color(0xFFF8F0FF),
                const Color(0xFFFFF8E7),
                const Color(0xFFFFFFFF),
              ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    // 2. Animated Orbs
    // Movement range ~30-40px
    final double moveX1 = math.sin(animationValue * math.pi * 2) * 40;
    final double moveY1 = math.cos(animationValue * math.pi * 2) * 30;

    final double moveX2 = math.cos(animationValue * math.pi * 2) * 40;
    final double moveY2 = math.sin(animationValue * math.pi * 2) * 30;

    final double moveX3 = math.sin((animationValue + 0.5) * math.pi * 2) * 35;
    final double moveY3 = math.cos((animationValue + 0.5) * math.pi * 2) * 35;

    // Orb 1 (top-right area): Signature Magenta (#8A1083)
    final Offset center1 =
        Offset(size.width * 0.8 + moveX1, size.height * 0.2 + moveY1);
    final Paint paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8A1083).withValues(alpha: isDark ? 0.45 : 0.15),
          const Color(0xFF8A1083).withValues(alpha: 0.0),
        ],
      ).createShader(
          Rect.fromCircle(center: center1, radius: size.width * 0.7));
    canvas.drawCircle(center1, size.width * 0.7, paint1);

    // Orb 2 (bottom-left area): Deep Brand Purple (#2A0845)
    final Offset center2 =
        Offset(size.width * 0.2 + moveX2, size.height * 0.8 + moveY2);
    final Paint paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2A0845).withValues(alpha: isDark ? 0.65 : 0.18),
          const Color(0xFF2A0845).withValues(alpha: 0.0),
        ],
      ).createShader(
          Rect.fromCircle(center: center2, radius: size.width * 0.8));
    canvas.drawCircle(center2, size.width * 0.8, paint2);

    // Orb 3 (center-left): Warm Amber (#FFAB00)
    final Offset center3 =
        Offset(size.width * 0.3 + moveX3, size.height * 0.5 + moveY3);
    final Paint paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFAB00).withValues(alpha: isDark ? 0.14 : 0.08),
          const Color(0xFFFFAB00).withValues(alpha: 0.0),
        ],
      ).createShader(
          Rect.fromCircle(center: center3, radius: size.width * 0.5));
    canvas.drawCircle(center3, size.width * 0.5, paint3);
  }

  @override
  bool shouldRepaint(covariant _AuroraBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}
