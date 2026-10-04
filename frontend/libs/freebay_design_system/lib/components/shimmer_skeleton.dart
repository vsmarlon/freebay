import 'package:flutter/material.dart';
import '../tokens/theme_extension.dart';
import '../tokens/app_motion.dart';

class ShimmerScope extends StatefulWidget {
  final Widget child;

  const ShimmerScope({super.key, required this.child});

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller?.dispose();
      _controller = null;
    } else {
      _controller ??= AnimationController(
        vsync: this,
        duration: AppMotion.shimmer,
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerAnimation(notifier: _controller, child: widget.child);
  }
}

class _ShimmerAnimation extends InheritedNotifier<AnimationController> {
  const _ShimmerAnimation({required super.notifier, required super.child});
}

class ShimmerBlock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final animation = context
        .dependOnInheritedWidgetOfExactType<_ShimmerAnimation>()
        ?.notifier;
    final base = baseColor ?? context.surfaceColor;
    final highlight = highlightColor ?? context.surfaceHighColor;
    final value = animation?.value ?? 0.5;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Color.lerp(base, highlight, value)),
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
    final list = ListView.builder(
      shrinkWrap: true,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
    return context.dependOnInheritedWidgetOfExactType<_ShimmerAnimation>() ==
            null
        ? ShimmerScope(child: list)
        : list;
  }
}

class SkeletonPage extends StatelessWidget {
  final Widget child;

  const SkeletonPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
    return context.dependOnInheritedWidgetOfExactType<_ShimmerAnimation>() ==
            null
        ? ShimmerScope(child: page)
        : page;
  }
}
