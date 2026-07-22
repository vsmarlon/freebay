import 'package:flutter/material.dart';
import 'package:freebay/core/components/brutalist_filter_chip.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

const _maxPriceReais = 5000.0;

const _sortLabels = {
  'recent': 'Recentes',
  'price_asc': 'Menor preço',
  'price_desc': 'Maior preço',
  'popular': 'Populares',
};

const _conditionLabels = {'NEW': 'Novo', 'USED': 'Usado'};

class ProductFilterBar extends StatelessWidget {
  final String sort;
  final String? condition;
  final RangeValues? priceRange;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String?> onConditionChanged;
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
    final range = priceRange ?? const RangeValues(0, _maxPriceReais);

    return Container(
      width: double.infinity,
      color: context.isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, 'ORDENAR POR'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in _sortLabels.entries) ...[
                  BrutalistFilterChip(
                    label: entry.value,
                    selected: sort == entry.key,
                    onTap: () => onSortChanged(entry.key),
                  ),
                  Spacing.hSm,
                ],
              ],
            ),
          ),
          Spacing.vMd,
          _label(context, 'CONDIÇÃO'),
          const SizedBox(height: 8),
          Row(
            children: [
              BrutalistFilterChip(
                label: 'Todos',
                selected: condition == null,
                onTap: () => onConditionChanged(null),
              ),
              Spacing.hSm,
              for (final entry in _conditionLabels.entries) ...[
                BrutalistFilterChip(
                  label: entry.value,
                  selected: condition == entry.key,
                  onTap: () => onConditionChanged(entry.key),
                ),
                Spacing.hSm,
              ],
            ],
          ),
          Spacing.vMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label(context, 'PREÇO'),
              Text(
                'R\$ ${range.start.round()} — R\$ ${range.end.round()}${range.end >= _maxPriceReais ? '+' : ''}',
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
            min: 0,
            max: _maxPriceReais,
            divisions: 50,
            activeColor: AppColors.primaryContainer,
            inactiveColor: AppColors.mediumGray,
            labels: RangeLabels(
              'R\$ ${range.start.round()}',
              'R\$ ${range.end.round()}',
            ),
            onChanged: (value) {
              final isFullRange =
                  value.start == 0 && value.end >= _maxPriceReais;
              onPriceRangeChanged(isFullRange ? null : value);
            },
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}
