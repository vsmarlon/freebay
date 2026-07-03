import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isDark = context.isDark;
    final available = product.quantity - product.soldCount;
    final maxQty = available > 10 ? 10 : available;
    final canAdd = available > 0 && product.status != 'SOLD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.mediumGray.withAlpha(50)
                : AppColors.lightGray,
            width: 1,
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
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const Spacer(),
                  _QuantityControl(
                    value: _quantity,
                    min: 1,
                    max: maxQty,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: canAdd
                        ? () async {
                            final ok = await ref
                                .read(cartProvider.notifier)
                                .addToCart(product.id, quantity: _quantity);
                            if (!context.mounted) return;
                            if (!ok) {
                              final error = ref.read(cartProvider).error;
                              AppSnackbar.error(
                                context,
                                error ??
                                    'Não foi possível adicionar ao carrinho',
                              );
                              return;
                            }
                            AppSnackbar.success(
                                context, 'Produto adicionado ao carrinho');
                          }
                        : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: canAdd
                            ? (isDark
                                ? AppColors.surfaceContainerDark
                                : AppColors.lightGray)
                            : AppColors.mediumGray.withAlpha(50),
                        border: Border.all(
                          color: canAdd
                              ? (isDark ? AppColors.white : AppColors.onSurface)
                              : AppColors.mediumGray.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          canAdd ? 'Adicionar' : 'Indisponível',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: canAdd
                                ? (isDark
                                    ? AppColors.white
                                    : AppColors.onSurface)
                                : AppColors.mediumGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Comprar agora',
                    onPressed: canAdd
                        ? () {
                            context.push(
                                '/profile/payment?productId=${product.id}');
                          }
                        : null,
                  ),
                ),
              ],
            ),
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
            color: isDark ? AppColors.white : AppColors.darkGray,
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

  const _QuantityButton({
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.lightGray,
          border: Border.all(
            color: isDark
                ? AppColors.mediumGray.withAlpha(100)
                : AppColors.mediumGray.withAlpha(50),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? (isDark ? AppColors.white : AppColors.darkGray)
              : AppColors.mediumGray,
        ),
      ),
    );
  }
}
