import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class EyebrowLabel extends StatelessWidget {
  final String text;
  final bool uppercase;

  const EyebrowLabel(this.text, {super.key, this.uppercase = true});

  @override
  Widget build(BuildContext context) {
    return Text(
      uppercase ? text.toUpperCase() : text,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}
