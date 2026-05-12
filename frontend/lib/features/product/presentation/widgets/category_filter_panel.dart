import 'package:flutter/material.dart';
import 'package:freebay/core/components/brutalist_filter_chip.dart';
import 'package:freebay/core/theme/theme_extension.dart';
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
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BrutalistFilterChip(
                label: 'Todos',
                selected: selectedCategory == null,
                onTap: () => onCategorySelected(null),
              ),
              ..._flattenCategories(categories),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _flattenCategories(List<CategoryEntity> cats, {int indent = 0}) {
    final widgets = <Widget>[];
    for (final cat in cats) {
      final isSelected = selectedCategory == cat.id;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent * 12.0),
          child: BrutalistFilterChip(
            label: cat.name,
            selected: isSelected,
            onTap: () => onCategorySelected(isSelected ? null : cat.id),
          ),
        ),
      );
      if (cat.children.isNotEmpty) {
        widgets.addAll(_flattenCategories(cat.children, indent: indent + 1));
      }
    }
    return widgets;
  }
}
