import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
    final strings = l10n(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        BrutalistFilterChip(
          label: strings.feedFilterAll,
          selected: currentFilter == FeedContentFilter.all,
          onTap: () => onChanged(FeedContentFilter.all),
        ),
        BrutalistFilterChip(
          label: strings.feedFilterSocial,
          selected: currentFilter == FeedContentFilter.socialOnly,
          onTap: () => onChanged(FeedContentFilter.socialOnly),
        ),
        BrutalistFilterChip(
          label: strings.feedFilterSales,
          selected: currentFilter == FeedContentFilter.sellingOnly,
          onTap: () => onChanged(FeedContentFilter.sellingOnly),
        ),
      ],
    );
  }
}
