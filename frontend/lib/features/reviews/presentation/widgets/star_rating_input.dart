import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';

class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final bool enabled;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = value >= starValue;

        return GestureDetector(
          onTap: enabled ? () => onChanged(starValue) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedScale(
              scale: isFilled ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear,
              child: Icon(
                isFilled ? Icons.star : Icons.star_outline,
                size: size,
                color: isFilled
                    ? AppColors.warning
                    : AppColors.outline,
              ),
            ),
          ),
        );
      }),
    );
  }
}
