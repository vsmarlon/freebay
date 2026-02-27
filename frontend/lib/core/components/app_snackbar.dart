import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';

enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = switch (type) {
      AppSnackbarType.success => AppColors.accentGreen,
      AppSnackbarType.error => AppColors.error,
      AppSnackbarType.warning => AppColors.warning,
      AppSnackbarType.info => AppColors.primaryPurple,
    };

    final icon = switch (type) {
      AppSnackbarType.success => Icons.check_circle_outline,
      AppSnackbarType.error => Icons.error_outline,
      AppSnackbarType.warning => Icons.warning_amber_outlined,
      AppSnackbarType.info => Icons.info_outline,
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.darkGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.info);
}
