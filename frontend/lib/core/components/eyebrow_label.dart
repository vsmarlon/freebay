import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class EyebrowLabel extends StatelessWidget {
  final String text;

  const EyebrowLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
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
