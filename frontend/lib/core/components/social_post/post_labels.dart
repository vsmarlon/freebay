import 'package:flutter/material.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class PostTypePill extends StatelessWidget {
  final bool isProduct;

  const PostTypePill({super.key, required this.isProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: isProduct ? AppColors.brutalistGradient : null,
        color: isProduct ? null : context.surfaceMidColor,
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: Text(
        isProduct ? 'VENDA' : 'SOCIAL',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: isProduct ? AppColors.onPrimary : context.textPrimary,
        ),
      ),
    );
  }
}

class PostPriceTag extends StatelessWidget {
  final double price;

  const PostPriceTag({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: Text(
        CurrencyUtils.formatReais(price),
        style: const TextStyle(
          fontFamily: AppTypography.headlineFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryContainer,
          height: 1,
        ),
      ),
    );
  }
}
