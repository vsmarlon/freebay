import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_depth.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_typography.dart';
import '../tokens/spacing.dart';
import '../tokens/theme_extension.dart';

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
    final scheme = context.colors;
    final isEnabled = !widget.isLoading && widget.onPressed != null;
    final backgroundColor = _backgroundColor(scheme, isEnabled);
    final foregroundColor = _foregroundColor(scheme, isEnabled);
    final border = _border(scheme, isEnabled);
    final shadowColor = _shadowColor(scheme, isEnabled);
    final gradient = widget.variant == AppButtonVariant.primary && isEnabled
        ? AppColors.brutalistGradient
        : null;

    final double height;
    final double horizontalPadding;
    final TextStyle textStyle;

    switch (widget.size) {
      case AppButtonSize.compact:
        height = 36.0;
        horizontalPadding = Spacing.sm + 4;
        textStyle = AppTypography.button.copyWith(fontSize: 13);
      case AppButtonSize.standard:
        height = 48.0;
        horizontalPadding = Spacing.md;
        textStyle = AppTypography.button;
      case AppButtonSize.large:
        height = 56.0;
        horizontalPadding = Spacing.lg;
        textStyle = AppTypography.button.copyWith(
          fontSize: 16,
          letterSpacing: 0.5,
        );
    }

    return AnimatedContainer(
      duration: AppMotion.tap,
      transform: Matrix4.translationValues(
        _isPressed ? AppDepth.pressOffset : 0.0,
        _isPressed ? AppDepth.pressOffset : 0.0,
        0.0,
      ),
      child: SizedBox(
        width: widget.width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? backgroundColor : null,
            border: border,
            boxShadow: shadowColor != null && !_isPressed
                ? AppDepth.hard(shadowColor)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled
                  ? () {
                      HapticFeedback.lightImpact();
                      widget.onPressed?.call();
                    }
                  : null,
              onHighlightChanged: isEnabled
                  ? (highlighted) {
                      setState(() => _isPressed = highlighted);
                    }
                  : null,
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
                            Flexible(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                semanticsLabel: widget.label,
                                style: textStyle.copyWith(
                                  color: foregroundColor,
                                ),
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
    );
  }

  Color _backgroundColor(ColorScheme scheme, bool isEnabled) {
    if (!isEnabled) return scheme.surfaceContainerHigh;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primaryContainer;
      case AppButtonVariant.secondary:
        return scheme.surface;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return scheme.error;
    }
  }

  Color _foregroundColor(ColorScheme scheme, bool isEnabled) {
    if (!isEnabled) return scheme.onSurfaceVariant;

    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return AppColors.onPrimary;
      case AppButtonVariant.secondary:
        return scheme.onSurface;
      case AppButtonVariant.ghost:
        return AppColors.primaryContainer;
    }
  }

  Border? _border(ColorScheme scheme, bool isEnabled) {
    if (!isEnabled) {
      return Border.all(
        color: scheme.outlineVariant,
        width: AppDepth.borderThin,
      );
    }

    switch (widget.variant) {
      case AppButtonVariant.ghost:
        return Border.all(
          color: AppColors.primaryContainer,
          width: AppDepth.borderThin,
        );
      case AppButtonVariant.secondary:
        return Border.all(color: scheme.onSurface, width: AppDepth.borderThick);
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return null;
    }
  }

  Color? _shadowColor(ColorScheme scheme, bool isEnabled) {
    if (!isEnabled) return null;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return scheme.onSurface;
      case AppButtonVariant.danger:
        return scheme.error;
      case AppButtonVariant.ghost:
        return null;
    }
  }
}
