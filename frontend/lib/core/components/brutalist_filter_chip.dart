import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class BrutalistFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const BrutalistFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brutalistGradient : null,
          color: selected ? null : context.surfaceColor,
          border: Border.all(
            color: selected ? AppColors.primaryContainer : AppColors.onSurface,
            width: 2,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ).copyWith(
            color: selected ? AppColors.onPrimary : context.textPrimary,
          ),
        ),
      ),
    );
  }
}