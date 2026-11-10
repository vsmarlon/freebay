import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/domain/product_filters.dart';

class ProductDetailBottomSheet extends ConsumerStatefulWidget {
  final ProductEntity product;

  const ProductDetailBottomSheet({super.key, required this.product});

  @override
  ConsumerState<ProductDetailBottomSheet> createState() =>
      _ProductDetailBottomSheetState();
}

class _ProductDetailBottomSheetState
    extends ConsumerState<ProductDetailBottomSheet> {
  int _quantity = 1;
  bool _isAdding = false;

  Future<void> _addToCart() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    final ok = await ref
        .read(cartProvider.notifier)
        .addToCart(widget.product.id, quantity: _quantity);
    if (!mounted) return;
    setState(() => _isAdding = false);
    if (!ok) {
      AppSnackbar.handleFailure(context, ref.read(cartProvider).error);
      return;
    }
    AppSnackbar.success(context, 'Produto adicionado ao carrinho');
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final product = widget.product;
    final isDark = context.isDark;
    final available = product.quantity - product.soldCount;
    final maxQty = available > 10 ? 10 : available;
    final canAdd = available > 0 && product.status == ProductStatus.active;
    final canTapAdd = canAdd && !_isAdding;
    // The order-create contract accepts a single unit only, so the shortcut
    // stays off while a quantity above 1 is selected.
    final canBuyNow = canAdd && _quantity == 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? context.textSecondary.withAlpha(50)
                : AppColors.lightGray,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.quantity > 1 && canAdd) ...[
              Row(
                children: [
                  Text(
                    'Quantidade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    label: strings.cartQuantity(_quantity),
                    child: _QuantityControl(
                      value: _quantity,
                      min: 1,
                      max: maxQty,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _quantity = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: canTapAdd ? _addToCart : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: canAdd
                            ? (isDark
                                  ? AppColors.surfaceContainerDark
                                  : AppColors.lightGray)
                            : context.textSecondary.withAlpha(50),
                        border: Border.all(
                          color: canAdd
                              ? (context.textPrimary)
                              : context.textSecondary.withAlpha(50),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          canAdd
                              ? strings.productAddToCart
                              : strings.productUnavailableLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: canAdd
                                ? (isDark
                                      ? AppColors.white
                                      : AppColors.onSurface)
                                : context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: strings.productBuyNow,
                    onPressed: canBuyNow
                        ? () {
                            context.push(
                              AppRoutes.profilePaymentWith(product.id),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
            if (canAdd && _quantity > 1) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.textSecondary,
                  ),
                  Spacing.hSm,
                  // ponytail: reuse of the add-to-cart copy; proper hint key
                  // (e.g. productBuyNowQuantityHint) is pending the l10n owner.
                  Expanded(
                    child: Text(
                      strings.productAddToCart,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _QuantityControl({
    required this.value,
    required this.min,
    required this.max,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(
          icon: Icons.remove,
          isDark: isDark,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 16),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        _QuantityButton(
          icon: Icons.add,
          isDark: isDark,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border.all(
            color: isDark
                ? context.textSecondary.withAlpha(100)
                : context.textSecondary.withAlpha(50),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? (context.textPrimary) : context.textSecondary,
        ),
      ),
    );
  }
}
