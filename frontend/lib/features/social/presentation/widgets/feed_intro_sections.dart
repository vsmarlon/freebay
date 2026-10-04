import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_filters.dart';
import 'package:freebay/features/stories/stories.dart';

class FeedIntroSections extends StatelessWidget {
  final FeedType feedType;
  final FeedContentFilter contentFilter;
  final ValueChanged<FeedType> onFeedTypeChanged;
  final ValueChanged<FeedContentFilter> onContentFilterChanged;
  final VoidCallback onCompose;

  const FeedIntroSections({
    super.key,
    required this.feedType,
    required this.contentFilter,
    required this.onFeedTypeChanged,
    required this.onContentFilterChanged,
    required this.onCompose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacing.vMd,
        const StoriesRow(),
        Spacing.vSm,
        FeedTitle(
          currentType: feedType,
          contentFilter: contentFilter,
          onFeedTypeChanged: onFeedTypeChanged,
          onContentFilterChanged: onContentFilterChanged,
        ),
        Spacing.vSm,
        FeedComposerPrompt(onTap: onCompose),
      ],
    );
  }
}

class FeedTitle extends StatelessWidget {
  final FeedType currentType;
  final FeedContentFilter contentFilter;
  final ValueChanged<FeedType> onFeedTypeChanged;
  final ValueChanged<FeedContentFilter> onContentFilterChanged;

  const FeedTitle({
    super.key,
    required this.currentType,
    required this.contentFilter,
    required this.onFeedTypeChanged,
    required this.onContentFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<FeedType>(
            initialValue: currentType,
            onSelected: onFeedTypeChanged,
            offset: const Offset(0, 40),
            color: context.isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: context.borderColor, width: 2),
            ),
            itemBuilder: (context) => [
              _feedTypeItem(
                context,
                FeedType.explore,
                Icons.explore,
                'EXPLORAR',
              ),
              _feedTypeItem(
                context,
                FeedType.following,
                Icons.people,
                'SEGUINDO',
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceContainerLow,
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentType == FeedType.explore
                        ? Icons.explore
                        : Icons.people,
                    size: 16,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentType == FeedType.explore ? 'EXPLORE' : 'SEGUINDO',
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: context.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FeedContentFilterBar(
          currentFilter: contentFilter,
          onChanged: onContentFilterChanged,
        ),
      ],
    );
  }

  PopupMenuItem<FeedType> _feedTypeItem(
    BuildContext context,
    FeedType type,
    IconData icon,
    String label,
  ) {
    final selected = currentType == type;
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            color: selected
                ? AppColors.primaryContainer
                : context.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              color: selected
                  ? AppColors.primaryContainer
                  : context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedComposerPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const FeedComposerPrompt({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border.all(color: context.borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                color: AppColors.primaryContainer,
                child: const Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Criar post social ou anúncio de venda',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
              ),
              const Icon(
                Icons.add,
                color: AppColors.primaryContainer,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
