import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class CategorySelectorField extends StatelessWidget {
  final AsyncValue<List<CategoryEntity>> categoriesAsync;
  final CategoryEntity? selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onRetry;

  const CategorySelectorField({
    super.key,
    required this.categoriesAsync,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return categoriesAsync.when(
      data: (categories) => InkWell(
        onTap: () => _showCategoryPicker(
          context,
          categories,
          selectedCategory?.id,
          onCategorySelected,
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: context.bgColor,
          child: Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.productCategory,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                      ),
                    ),
                    Spacing.vXs,
                    Text(
                      selectedCategory?.name ?? strings.productSelectCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: AppColors.primaryContainer,
              ),
            ],
          ),
        ),
      ),
      loading: () => Container(
        height: 64,
        color: context.bgColor,
        child: const Center(child: ShimmerBlock(width: 24, height: 24)),
      ),
      error: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        color: context.bgColor,
        child: Row(
          children: [
            Expanded(
              child: Text(
                strings.productCategoriesLoadFailed,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: strings.commonRetry,
              size: AppButtonSize.compact,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    List<CategoryEntity> categories,
    String? selectedCategoryId,
    void Function(String) onSelected,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showBrutalistSheet<void>(
      context: context,
      title: l10n(context).productChooseCategory,
      builder: (ctx) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category.id == selectedCategoryId;
            return InkWell(
              onTap: () {
                onSelected(category.id);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                color: isSelected
                    ? (isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerHighest)
                    : (context.bgColor),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: AppColors.primaryContainer,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
