import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool usePrimaryColor;
  final bool uppercaseLabel;

  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.usePrimaryColor = false,
    this.uppercaseLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = usePrimaryColor
        ? AppColors.primaryPurple
        : context.textPrimary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          uppercaseLabel ? label.toUpperCase() : label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: uppercaseLabel ? 10 : 12,
            fontWeight: uppercaseLabel ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: uppercaseLabel ? 0.5 : 0,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}