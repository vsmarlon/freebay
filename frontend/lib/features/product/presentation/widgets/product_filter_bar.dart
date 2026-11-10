import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

const _priceDivisions = 50;

class ProductFilterBar extends StatefulWidget {
  final ProductSort sort;
  final ProductCondition? condition;
  final RangeValues? priceRange;
  final ValueChanged<ProductSort> onSortChanged;
  final ValueChanged<ProductCondition?> onConditionChanged;
  final ValueChanged<RangeValues?> onPriceRangeChanged;
  final VoidCallback onClear;

  const ProductFilterBar({
    super.key,
    required this.sort,
    required this.condition,
    required this.priceRange,
    required this.onSortChanged,
    required this.onConditionChanged,
    required this.onPriceRangeChanged,
    required this.onClear,
  });

  @override
  State<ProductFilterBar> createState() => _ProductFilterBarState();
}

class _ProductFilterBarState extends State<ProductFilterBar> {
  late RangeValues _draftRange;

  RangeValues get _fullRange =>
      const RangeValues(0, ProductFilterLimits.maxPriceReais);

  RangeValues get _appliedRange => widget.priceRange ?? _fullRange;

  @override
  void initState() {
    super.initState();
    _draftRange = _appliedRange;
  }

  @override
  void didUpdateWidget(ProductFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.priceRange != oldWidget.priceRange) {
      _draftRange = _appliedRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      width: double.infinity,
      color: context.isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyebrowLabel(strings.productSortBy),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in ProductSort.values) ...[
                  BrutalistFilterChip(
                    label: switch (option) {
                      ProductSort.recent => strings.productSortRecent,
                      ProductSort.priceAsc => strings.productSortPriceLowHigh,
                      ProductSort.priceDesc => strings.productSortPriceHighLow,
                      ProductSort.popular => strings.productSortPopular,
                    },
                    selected: widget.sort == option,
                    onTap: () => widget.onSortChanged(option),
                  ),
                  Spacing.hSm,
                ],
              ],
            ),
          ),
          Spacing.vMd,
          EyebrowLabel(strings.productConditionLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              BrutalistFilterChip(
                label: strings.productAll,
                selected: widget.condition == null,
                onTap: () => widget.onConditionChanged(null),
              ),
              Spacing.hSm,
              for (final option in ProductCondition.values) ...[
                BrutalistFilterChip(
                  label: option == ProductCondition.isNew
                      ? strings.productNew
                      : strings.productUsed,
                  selected: widget.condition == option,
                  onTap: () => widget.onConditionChanged(option),
                ),
                Spacing.hSm,
              ],
            ],
          ),
          Spacing.vMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(strings.productPriceLabel),
              Text(
                '${CurrencyUtils.formatReais(_draftRange.start)} — '
                '${CurrencyUtils.formatReais(_draftRange.end)}'
                '${_draftRange.end >= ProductFilterLimits.maxPriceReais ? '+' : ''}',
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
            values: _draftRange,
            max: ProductFilterLimits.maxPriceReais,
            divisions: _priceDivisions,
            activeColor: AppColors.primaryContainer,
            inactiveColor: context.textSecondary,
            labels: RangeLabels(
              CurrencyUtils.formatReais(_draftRange.start),
              CurrencyUtils.formatReais(_draftRange.end),
            ),
            onChanged: (value) {
              setState(() => _draftRange = value);
            },
          ),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: strings.commonClear,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.compact,
                  onPressed: widget.onClear,
                ),
              ),
              Spacing.hSm,
              Expanded(
                child: AppButton(
                  label: strings.commonApply,
                  size: AppButtonSize.compact,
                  onPressed: () {
                    final isFullRange =
                        _draftRange.start == 0 &&
                        _draftRange.end >= ProductFilterLimits.maxPriceReais;
                    widget.onPriceRangeChanged(
                      isFullRange ? null : _draftRange,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
