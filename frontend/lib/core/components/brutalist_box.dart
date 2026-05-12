import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class BrutalistBox extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;

  const BrutalistBox({
    super.key,
    this.child,
    this.padding,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : (elevated
                ? AppColors.surfaceContainerLowest
                : AppColors.surfaceContainer),
        border: Border.all(
          color: AppColors.onSurface,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}