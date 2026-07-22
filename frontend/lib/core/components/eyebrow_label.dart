import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

/// Small all-caps Inter label that sits above a block of content.
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
