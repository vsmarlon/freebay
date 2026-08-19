import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import 'spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { standard, compact, large }

class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isLoading && widget.onPressed != null;
    final backgroundColor = _backgroundColor(isEnabled);
    final foregroundColor = _foregroundColor(isEnabled);
    final border = _border(isEnabled);
    final shadowColor = _shadowColor(isEnabled);
    final gradient = widget.variant == AppButtonVariant.primary && isEnabled
        ? AppColors.brutalistGradient
        : null;

    final double height;
    final double horizontalPadding;
    final TextStyle textStyle;

    switch (widget.size) {
      case AppButtonSize.compact:
        height = 36.0;
        horizontalPadding = 12.0;
        textStyle = AppTypography.button.copyWith(fontSize: 13);
        break;
      case AppButtonSize.standard:
        height = 48.0;
        horizontalPadding = 16.0;
        textStyle = AppTypography.button;
        break;
      case AppButtonSize.large:
        height = 56.0;
        horizontalPadding = 24.0;
        textStyle = AppTypography.button.copyWith(
          fontSize: 16,
          letterSpacing: 0.5,
        );
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      transform: Matrix4.translationValues(
        _isPressed ? 3.0 : 0.0,
        _isPressed ? 3.0 : 0.0,
        0.0,
      ),
      child: SizedBox(
        width: widget.width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            gradient: gradient,
            color: gradient == null ? backgroundColor : null,
            border: border,
            boxShadow: shadowColor != null
                ? [
                    BoxShadow(
                      color: shadowColor,
                      offset: _isPressed
                          ? const Offset(0, 0)
                          : const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? () {
                  HapticFeedback.lightImpact();
                  widget.onPressed?.call();
                } : null,
                onHighlightChanged: isEnabled ? (highlighted) {
                  setState(() => _isPressed = highlighted);
                } : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                foregroundColor,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  size: 20,
                                  color: foregroundColor,
                                ),
                                Spacing.hSm,
                              ],
                              Text(
                                widget.label,
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
        ),
      ),
    );
  }

  Color _backgroundColor(bool isEnabled) {
    if (!isEnabled) {
      return AppColors.surfaceContainerHighest;
    }

    switch (widget.variant) {
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

    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
        return AppColors.onPrimary;
      case AppButtonVariant.ghost:
        return AppColors.primaryContainer;
    }
  }

  Border? _border(bool isEnabled) {
    if (widget.variant == AppButtonVariant.ghost) {
      return Border.all(
        color: isEnabled ? AppColors.accentAmber : AppColors.outlineVariant,
        width: 1.5,
      );
    }

    if (!isEnabled) {
      return Border.all(color: AppColors.outlineVariant, width: 1.5);
    }

    if (widget.variant == AppButtonVariant.secondary) {
      return Border.all(color: AppColors.onSurface, width: 2);
    }

    return null;
  }

  Color? _shadowColor(bool isEnabled) {
    if (!isEnabled) return null;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primary.withAlpha(180);
      case AppButtonVariant.secondary:
        return AppColors.onSurface.withAlpha(100);
      case AppButtonVariant.danger:
        return AppColors.error.withAlpha(150);
      case AppButtonVariant.ghost:
        return null;
    }
  }
}
