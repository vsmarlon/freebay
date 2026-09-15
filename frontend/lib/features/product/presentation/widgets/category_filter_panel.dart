import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';

class CategoryFilterPanel extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterPanel({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Faixa horizontal com gesto próprio: nunca compete com a rolagem
    // vertical da grade de produtos.
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            BrutalistFilterChip(
              label: 'Todos',
              selected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            ),
            const SizedBox(width: 8),
            ..._flattenCategories(categories),
          ],
        ),
      ),
    );
  }

  List<Widget> _flattenCategories(List<CategoryEntity> cats) {
    final widgets = <Widget>[];
    for (final cat in cats) {
      final isSelected = selectedCategory == cat.id;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: BrutalistFilterChip(
            label: cat.name,
            selected: isSelected,
            onTap: () => onCategorySelected(isSelected ? null : cat.id),
          ),
        ),
      );
      if (cat.children.isNotEmpty) {
        widgets.addAll(_flattenCategories(cat.children));
      }
    }
    return widgets;
  }
}
