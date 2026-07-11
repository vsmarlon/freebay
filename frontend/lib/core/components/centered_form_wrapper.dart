import 'package:flutter/material.dart';

class CenteredFormWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool center;

  const CenteredFormWrapper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(padding: padding, child: child);

    if (center) {
      content = Center(child: content);
    }

    return SafeArea(child: content);
  }
}
