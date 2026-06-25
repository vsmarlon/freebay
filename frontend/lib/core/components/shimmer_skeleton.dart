import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ??
        (context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLow);
    final highlight = widget.highlightColor ??
        (context.isDark
            ? AppColors.surfaceContainerLowDark
            : AppColors.surfaceContainerLowest);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
              begin: Alignment(-1, 0),
              end: Alignment(1, 0),
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: widget.borderRadius != null
                  ? BorderRadius.circular(widget.borderRadius!)
                  : BorderRadius.zero,
            ),
          ),
        );
      },
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollPhysics? physics;

  const SkeletonList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class SkeletonPage extends StatelessWidget {
  final Widget child;

  const SkeletonPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}

class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBlock(height: 200),
          const SizedBox(height: 24),
          ShimmerBlock(height: 20, width: 160),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color:
                context.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(height: 14, width: 100),
                SizedBox(height: 8),
                ShimmerBlock(height: 14, width: 220),
                SizedBox(height: 16),
                ShimmerBlock(height: 14, width: 100),
                SizedBox(height: 8),
                ShimmerBlock(height: 14, width: 220),
                SizedBox(height: 16),
                ShimmerBlock(height: 14, width: 100),
                SizedBox(height: 8),
                ShimmerBlock(height: 14, width: 220),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const ShimmerBlock(height: 20, width: 100),
          const SizedBox(height: 12),
          const ShimmerBlock(height: 120),
        ],
      ),
    );
  }
}
