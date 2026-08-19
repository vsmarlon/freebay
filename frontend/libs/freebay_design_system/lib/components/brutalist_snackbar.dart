import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

enum BrutalistSnackBarType { info, success, error, warning }

class BrutalistSnackBar {
  BrutalistSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    BrutalistSnackBarType type = BrutalistSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    HapticFeedback.mediumImpact();

    final Color bgColor;
    final Color textColor;
    final Color borderColor;
    final IconData icon;

    switch (type) {
      case BrutalistSnackBarType.success:
        bgColor = AppColors.success;
        textColor = AppColors.white;
        borderColor = AppColors.white;
        icon = Icons.check_circle_outline;
        break;
      case BrutalistSnackBarType.error:
        bgColor = AppColors.error;
        textColor = AppColors.white;
        borderColor = AppColors.white;
        icon = Icons.error_outline;
        break;
      case BrutalistSnackBarType.warning:
        bgColor = AppColors.warning;
        textColor = AppColors.black;
        borderColor = AppColors.black;
        icon = Icons.warning_amber_outlined;
        break;
      case BrutalistSnackBarType.info:
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.white;
        borderColor = AppColors.white;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      actionLabel.toUpperCase(),
                      style: AppTypography.brutalistTag.copyWith(
                        color: textColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
