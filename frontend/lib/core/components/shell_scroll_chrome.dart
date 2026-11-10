import 'package:flutter/widgets.dart';
import 'package:freebay/core/components/hide_on_scroll.dart';

class ShellScrollChromeScope extends InheritedWidget {
  const ShellScrollChromeScope({
    super.key,
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static ShellScrollChromeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScrollChromeScope>();

  @override
  bool updateShouldNotify(ShellScrollChromeScope oldWidget) =>
      oldWidget.animation != animation;
}

class ShellScrollHeader extends StatelessWidget {
  const ShellScrollHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ShellScrollChromeScope.maybeOf(context)?.animation;
    return animation == null
        ? child
        : CollapsingScrollBar(animation: animation, child: child);
  }
}
