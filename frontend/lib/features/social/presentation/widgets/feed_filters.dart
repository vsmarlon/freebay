import 'package:flutter/material.dart';
import 'package:freebay/core/components/brutalist_filter_chip.dart';
import 'package:freebay/core/freebay.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class FeedContentFilterBar extends StatelessWidget {
  final FeedContentFilter currentFilter;
  final ValueChanged<FeedContentFilter> onChanged;

  const FeedContentFilterBar({
    super.key,
    required this.currentFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        BrutalistFilterChip(
          label: 'Tudo',
          selected: currentFilter == FeedContentFilter.all,
          onTap: () => onChanged(FeedContentFilter.all),
        ),
        BrutalistFilterChip(
          label: 'Social',
          selected: currentFilter == FeedContentFilter.socialOnly,
          onTap: () => onChanged(FeedContentFilter.socialOnly),
        ),
        BrutalistFilterChip(
          label: 'Vendas',
          selected: currentFilter == FeedContentFilter.sellingOnly,
          onTap: () => onChanged(FeedContentFilter.sellingOnly),
        ),
      ],
    );
  }
}

class FeedTypeDropdown extends StatelessWidget {
  final FeedType currentType;
  final ValueChanged<FeedType> onChanged;

  const FeedTypeDropdown({
    super.key,
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FeedType>(
      initialValue: currentType,
      onSelected: onChanged,
      offset: const Offset(0, 32),
      color: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.onSurface, width: 2),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: FeedType.explore,
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.explore,
                size: 16,
                color: currentType == FeedType.explore
                    ? AppColors.primaryContainer
                    : AppColors.outline,
              ),
              Freebay.horizontalSpacing8,
              Text(
                'EXPLORE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentType == FeedType.explore
                      ? AppColors.primaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: FeedType.following,
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: currentType == FeedType.following
                    ? AppColors.primaryContainer
                    : AppColors.outline,
              ),
              Freebay.horizontalSpacing8,
              Text(
                'FOLLOWING',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentType == FeedType.following
                      ? AppColors.primaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaceMidColor,
          border: Border.all(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentType == FeedType.explore ? Icons.explore : Icons.people,
              size: 14,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              currentType == FeedType.explore ? 'EXPLORE' : 'FOLLOWING',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 14,
              color: context.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
