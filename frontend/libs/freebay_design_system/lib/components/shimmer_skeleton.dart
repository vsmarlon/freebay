import '../tokens/app_motion.dart';
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/theme_extension.dart';

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
    _controller = AnimationController(vsync: this, duration: AppMotion.shimmer)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.baseColor ??
        (context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLow);
    final highlight =
        widget.highlightColor ??
        (context.isDark
            ? AppColors.surfaceContainerLowDark
            : AppColors.surfaceContainerLowest);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, highlight, _controller.value),
            border: Border.all(color: AppColors.outlineVariant),
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
          const ShimmerBlock(height: 20, width: 160),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: context.isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceContainerLowest,
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

class ChatLoadingSkeleton extends StatelessWidget {
  const ChatLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ShimmerBlock(
              height: 48,
              width: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ShimmerBlock(
              height: 64,
              width: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ShimmerBlock(
              height: 40,
              width: MediaQuery.of(context).size.width * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
