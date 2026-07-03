import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { standard, compact }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.standard,
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
    final height = size == AppButtonSize.compact ? 36.0 : 48.0;
    final horizontalPadding = size == AppButtonSize.compact ? 12.0 : 0.0;
    final textStyle = size == AppButtonSize.compact
        ? AppTypography.button.copyWith(fontSize: 13)
        : AppTypography.button;

    return SizedBox(
      width: width,
      height: height,
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: isLoading
                    ? ShimmerBlock(
                        height: height,
                        width: width ?? double.infinity,
                        baseColor: variant == AppButtonVariant.ghost
                            ? AppColors.outlineVariant
                            : backgroundColor,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: foregroundColor),
                            Spacing.hSm,
                          ],
                          Text(
                            label,
                            style: textStyle.copyWith(
                              color: foregroundColor,
                            ),
                          ),
                        ],
                      ),
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
