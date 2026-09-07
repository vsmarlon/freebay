import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class BrutalistBackground extends StatefulWidget {
  final Widget child;
  final bool? forceDark;

  const BrutalistBackground({required this.child, this.forceDark, super.key});

  @override
  State<BrutalistBackground> createState() => _BrutalistBackgroundState();
}

class _BrutalistBackgroundState extends State<BrutalistBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.ambient)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.forceDark ?? (Theme.of(context).brightness == Brightness.dark);

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
    final Rect rect = Offset.zero & size;
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                AppColors.surfaceContainerLowestDark,
                AppColors.surfaceDark,
                AppColors.surfaceContainerLowDark,
                AppColors.surfaceContainerLowestDark,
              ]
            : const [
                AppColors.surfaceContainerLowest,
                AppColors.surface,
                AppColors.surfaceContainerLow,
                AppColors.surfaceContainerLowest,
              ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    final double moveX1 = math.sin(animationValue * math.pi * 2) * 40;
    final double moveY1 = math.cos(animationValue * math.pi * 2) * 30;

    final Offset center1 = Offset(
      size.width * 0.8 + moveX1,
      size.height * 0.2 + moveY1,
    );
    final Paint paint1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.primaryContainer.withValues(
                alpha: isDark ? 0.45 : 0.15,
              ),
              AppColors.primaryContainer.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: center1, radius: size.width * 0.7),
          );
    canvas.drawCircle(center1, size.width * 0.7, paint1);
  }

  @override
  bool shouldRepaint(covariant _AuroraBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}
