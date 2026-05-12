import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.text,
    this.isDark = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              letterSpacing: -2,
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}