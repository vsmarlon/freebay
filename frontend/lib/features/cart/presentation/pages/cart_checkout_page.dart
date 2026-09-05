import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

class CartCheckoutPage extends ConsumerStatefulWidget {
  const CartCheckoutPage({super.key});

  @override
  ConsumerState<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends ConsumerState<CartCheckoutPage> {
  bool _isSubmitting = false;
  CartCheckoutEntity? _checkout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  Future<void> _submitCheckout() async {
    setState(() => _isSubmitting = true);
    final result = await ref.read(checkoutCartUsecaseProvider)();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (checkout) => setState(() => _checkout = checkout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    final cart = state.cart;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'CHECKOUT',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const SkeletonPage(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        ShimmerBlock(height: 80),
                        SizedBox(height: 12),
                        ShimmerBlock(height: 80),
                        SizedBox(height: 12),
                        ShimmerBlock(height: 80),
                      ],
                    ),
                  )
                : _checkout != null
                ? _buildResult(_checkout!)
                : cart.items.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'CARRINHO VAZIO',
                    subtitle: 'Adicione produtos ao carrinho para continuar.',
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final item = cart.items[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              color: context.surfaceColor,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.quantity}x',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    CurrencyUtils.formatCents(item.subtotal),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: context.surfaceColor,
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Total (${cart.totalItems} itens)',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      CurrencyUtils.formatCents(
                                        cart.totalPrice,
                                      ),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppButton(
                                label: 'GERAR CHECKOUT',
                                isLoading: _isSubmitting,
                                onPressed: _submitCheckout,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(CartCheckoutEntity checkout) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: context.surfaceColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHECKOUT GERADO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
              Spacing.vSm,
              Text(
                '${checkout.totalOrders} pedidos criados',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              Spacing.vSm,
              Text(
                'Total: ${CurrencyUtils.formatCents(checkout.totalAmount)}',
                style: TextStyle(fontSize: 16, color: context.textSecondary),
              ),
              Spacing.vMd,
              AppButton(
                label: 'VER MEUS PEDIDOS',
                onPressed: () => context.go('/orders'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
