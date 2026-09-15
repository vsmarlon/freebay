import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/core/router/app_routes.dart';

class CartCheckoutPage extends HookConsumerWidget {
  const CartCheckoutPage({super.key});

  Future<void> _submitCheckout(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(cartProvider.notifier).checkout();
    if (!ok && context.mounted) {
      AppSnackbar.error(
        context,
        ref.read(cartProvider).error ?? 'Erro ao gerar checkout.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() => ref.read(cartProvider.notifier).loadCart());
      return null;
    }, const []);
    final state = ref.watch(cartProvider);
    final cart = state.cart;
    final hasUnavailableItems = cart.items.any(
      (item) => item.product.status != 'ACTIVE',
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
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
                  : state.error != null
                  ? EmptyState.error(
                      message: state.error!,
                      onRetry: () => ref.read(cartProvider.notifier).loadCart(),
                    )
                  : state.lastCheckout != null
                  ? _buildResult(context, state.lastCheckout!)
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
                                        item.product.status == 'ACTIVE'
                                            ? item.product.title
                                            : '${item.product.title} (indisponível)',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  isLoading: state.isCheckingOut,
                                  onPressed: hasUnavailableItems
                                      ? null
                                      : () => _submitCheckout(context, ref),
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
      ),
    );
  }

  Widget _buildResult(BuildContext context, CartCheckoutEntity checkout) {
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
                onPressed: () => context.go(AppRoutes.orders),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
