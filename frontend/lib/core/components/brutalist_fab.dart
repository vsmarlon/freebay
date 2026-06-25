import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/theme/app_colors.dart';

/// The signature floating action button — Digital Brutalist.
///
/// Gradient block, 0px radius, 2px [AppColors.onSurface] frame, with a Material
/// [InkWell] ripple and a 150ms linear press-scale. Use this everywhere instead
/// of inlining a `GestureDetector`/`Container` FAB so the press animation stays
/// consistent across the app.
class BrutalistFab extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;

  const BrutalistFab({
    super.key,
    required this.onTap,
    this.icon = Icons.add,
    this.size = 56,
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
    return AnimatedScale(
      scale: _pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: AppColors.brutalistGradient,
          border: Border.all(color: AppColors.onSurface, width: 2),
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
    );
  }
}
