import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';
import 'spacing.dart';

class BrutalistErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final IconData icon;

  const BrutalistErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.error.withAlpha(40)
            : AppColors.errorContainer,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: AppColors.error,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 22,
          ),
          Spacing.hSm,
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: context.isDark ? AppColors.white : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: context.isDark ? AppColors.white : AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
