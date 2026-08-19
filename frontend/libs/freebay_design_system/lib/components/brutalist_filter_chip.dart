import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';

class BrutalistFilterChip extends StatelessWidget {
  final String label;
  final bool? selected;
  final bool? isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onSelected;
  final IconData? icon;

  const BrutalistFilterChip({
    super.key,
    required this.label,
    this.selected,
    this.isSelected,
    this.onTap,
    this.onSelected,
    this.icon,
  });

  bool get _active => isSelected ?? selected ?? false;
  VoidCallback? get _callback => onSelected ?? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _callback?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.linear,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _active ? AppColors.primaryContainer : context.surfaceColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: _active ? AppColors.primaryContainer : context.borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: _active ? AppColors.white : context.textPrimary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: AppTypography.brutalistTag.copyWith(
                color: _active ? AppColors.white : context.textPrimary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
