import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class BrutalistFab extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final String? semanticLabel;

  const BrutalistFab({
    super.key,
    required this.onTap,
    this.icon = Icons.add,
    this.size = 56,
    this.semanticLabel,
  });

  @override
  State<BrutalistFab> createState() => _BrutalistFabState();
}

class _BrutalistFabState extends State<BrutalistFab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final fab = Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppMotion.base,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: AppColors.brutalistGradient,
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onTap();
                },
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                splashColor: AppColors.onPrimary.withValues(alpha: 0.18),
                highlightColor: AppColors.onPrimary.withValues(alpha: 0.08),
                child: Icon(
                  widget.icon,
                  color: AppColors.onPrimary,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final label = widget.semanticLabel;
    return label == null ? fab : Tooltip(message: label, child: fab);
  }
}
