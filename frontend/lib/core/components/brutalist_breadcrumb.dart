import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}

class BrutalistBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  const BrutalistBreadcrumb({
    super.key,
    required this.items,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (items.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark
                    ? AppColors.mediumGray
                    : AppColors.onSurfaceVariant,
              ),
            );
          }
          final itemIndex = index ~/ 2;
          final item = items[itemIndex];
          final isLast = itemIndex == items.length - 1;
          if (isLast) {
            return Text(
              item.label,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: isDark
                    ? AppColors.primaryContainer
                    : AppColors.onSurface,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }
          return InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                item.label,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: isDark
                      ? AppColors.mediumGray
                      : AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
