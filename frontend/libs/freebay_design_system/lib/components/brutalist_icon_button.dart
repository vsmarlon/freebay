import '../tokens/app_depth.dart';
import '../tokens/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/theme_extension.dart';
import 'shimmer_skeleton.dart';

class BrutalistIconButton extends StatefulWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final bool isLoading;

  const BrutalistIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.isLoading = false,
  });

  @override
  State<BrutalistIconButton> createState() => _BrutalistIconButtonState();
}

class _BrutalistIconButtonState extends State<BrutalistIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = widget.gradient == null
        ? Border.all(color: widget.borderColor ?? context.borderColor)
        : null;

    final enabled = widget.onTap != null && !widget.isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (_) {
                  HapticFeedback.lightImpact();
                  setState(() => _isPressed = true);
                }
              : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onTap!();
                }
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          child: SizedBox(
            width: widget.size < 48 ? 48 : widget.size,
            height: widget.size < 48 ? 48 : widget.size,
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.forContext(context, AppMotion.tap),
                transform: Matrix4.translationValues(
                  _isPressed ? AppDepth.pressOffset : 0.0,
                  _isPressed ? AppDepth.pressOffset : 0.0,
                  0.0,
                ),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  color: widget.gradient == null
                      ? (widget.backgroundColor ?? context.surfaceColor)
                      : null,
                  border: effectiveBorder,
                ),
                child: Center(
                  child: widget.isLoading
                      ? ShimmerBlock(
                          width: widget.iconSize,
                          height: widget.iconSize,
                        )
                      : Icon(
                          widget.icon,
                          size: widget.iconSize,
                          color: widget.iconColor ?? context.textPrimary,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
