import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/product/domain/product_filters.dart';

const _priceDivisions = 50;

class ProductFilterBar extends StatelessWidget {
  final ProductSort sort;
  final ProductCondition? condition;
  final RangeValues? priceRange;
  final ValueChanged<ProductSort> onSortChanged;
  final ValueChanged<ProductCondition?> onConditionChanged;
  final ValueChanged<RangeValues?> onPriceRangeChanged;

  const ProductFilterBar({
    super.key,
    required this.sort,
    required this.condition,
    required this.priceRange,
    required this.onSortChanged,
    required this.onConditionChanged,
    required this.onPriceRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final range =
        priceRange ?? const RangeValues(0, ProductFilterLimits.maxPriceReais);

    return Container(
      width: double.infinity,
      color: context.isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Ordenar por'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in ProductSort.values) ...[
                  BrutalistFilterChip(
                    label: option.label,
                    selected: sort == option,
                    onTap: () => onSortChanged(option),
                  ),
                  Spacing.hSm,
                ],
              ],
            ),
          ),
          Spacing.vMd,
          const EyebrowLabel('Condição'),
          const SizedBox(height: 8),
          Row(
            children: [
              BrutalistFilterChip(
                label: 'Todos',
                selected: condition == null,
                onTap: () => onConditionChanged(null),
              ),
              Spacing.hSm,
              for (final option in ProductCondition.values) ...[
                BrutalistFilterChip(
                  label: option.label,
                  selected: condition == option,
                  onTap: () => onConditionChanged(option),
                ),
                Spacing.hSm,
              ],
            ],
          ),
          Spacing.vMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const EyebrowLabel('Preço'),
              Text(
                '${CurrencyUtils.formatReais(range.start)} — '
                '${CurrencyUtils.formatReais(range.end)}'
                '${range.end >= ProductFilterLimits.maxPriceReais ? '+' : ''}',
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: range,
            max: ProductFilterLimits.maxPriceReais,
            divisions: _priceDivisions,
            activeColor: AppColors.primaryContainer,
            inactiveColor: AppColors.mediumGray,
            labels: RangeLabels(
              CurrencyUtils.formatReais(range.start),
              CurrencyUtils.formatReais(range.end),
            ),
            onChanged: (value) {
              final isFullRange =
                  value.start == 0 &&
                  value.end >= ProductFilterLimits.maxPriceReais;
              onPriceRangeChanged(isFullRange ? null : value);
            },
          ),
        ],
      ),
    );
  }
}
