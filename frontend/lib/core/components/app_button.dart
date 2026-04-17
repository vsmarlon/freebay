import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;
    final backgroundColor = _backgroundColor(isEnabled);
    final foregroundColor = _foregroundColor(isEnabled);
    final border = _border(isEnabled);
    final gradient = variant == AppButtonVariant.primary && isEnabled
        ? AppColors.brutalistGradient
        : null;

    return SizedBox(
      width: width,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? backgroundColor : null,
          border: border,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: foregroundColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: AppTypography.button.copyWith(
                            color: foregroundColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(bool isEnabled) {
    if (!isEnabled) {
      return AppColors.surfaceContainerHighest;
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primaryContainer;
      case AppButtonVariant.secondary:
        return AppColors.onSurface;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color _foregroundColor(bool isEnabled) {
    if (!isEnabled) {
      return AppColors.onSurfaceVariant;
    }

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
        return AppColors.onPrimary;
      case AppButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  Border? _border(bool isEnabled) {
    if (variant == AppButtonVariant.ghost) {
      return Border.all(
        color: isEnabled ? AppColors.outline : AppColors.outlineVariant,
      );
    }

    if (!isEnabled) {
      return Border.all(color: AppColors.outlineVariant);
    }

    return null;
  }
}
