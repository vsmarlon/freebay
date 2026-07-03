import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';

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
    final isDark = context.isDark;
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
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          child: Row(
            children: [
              const Icon(Icons.category_outlined,
                  color: AppColors.primaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoria',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.onPrimaryContainer
                            : AppColors.primary,
                      ),
                    ),
                    Spacing.vXs,
                    Text(
                      selectedCategory?.name ?? 'Selecionar categoria',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward,
                  color: AppColors.primaryContainer),
            ],
          ),
        ),
      ),
      loading: () => Container(
        height: 64,
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        child: const Center(child: ShimmerBlock(width: 24, height: 24)),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Não foi possível carregar categorias agora.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Tentar',
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
    final isDark = context.isDark;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'ESCOLHER CATEGORIA',
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.onSurface,
                    ),
                  ),
                );
              }

              final category = categories[index - 1];
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
                      : (isDark ? AppColors.surfaceDark : AppColors.white),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isDark ? AppColors.white : AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check,
                            color: AppColors.primaryContainer),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
