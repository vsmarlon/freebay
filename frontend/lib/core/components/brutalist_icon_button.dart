import 'package:flutter/material.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class BrutalistIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? borderColor;
  final Gradient? gradient;

  const BrutalistIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.iconColor,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient,
            border: gradient == null
                ? Border.all(
                    color: borderColor ?? context.borderColor, width: 2)
                : null,
          ),
          child: Icon(icon,
              color: iconColor ?? context.textPrimary, size: iconSize),
        ),
      ),
    );
  }
}
