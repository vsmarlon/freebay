import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool usePrimaryColor;
  final bool uppercaseLabel;
  final double? size;

  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.usePrimaryColor = false,
    this.uppercaseLabel = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = usePrimaryColor
        ? AppColors.primaryContainer
        : context.textPrimary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontSize: size ?? 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Spacing.vXs,
        Text(
          uppercaseLabel ? label.toUpperCase() : label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: uppercaseLabel ? 10 : 12,
            fontWeight: uppercaseLabel ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: uppercaseLabel ? 0.5 : 0,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }

    return content;
  }
}
