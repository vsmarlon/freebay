import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/utils/date_utils.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.surfaceContainerLowDark
                : AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: context.borderColor.withAlpha(40),
              width: 1,
            ),
          ),
          child: Text(
            formatDateSeparator(date),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
