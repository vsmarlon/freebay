import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/core/router/app_routes.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  @override
  void initState() {
    super.initState();
    ref.read(cartProvider.notifier).loadCart();
  }

  @override
  Widget build(BuildContext context) {
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
              text: 'CARRINHO (${cart.totalItems})',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
              actions: [
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final ok = await ref
                          .read(cartProvider.notifier)
                          .clearCart();
                      if (!context.mounted) return;
                      if (ok) AppSnackbar.info(context, 'Carrinho limpo');
                    },
                    child: Text(
                      'Limpar',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
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
                        ],
                      ),
                    )
                  : state.error != null && cart.items.isEmpty
                  ? EmptyState.error(
                      message: state.error!,
                      onRetry: () => ref.read(cartProvider.notifier).loadCart(),
                    )
                  : cart.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'CARRINHO VAZIO',
                      subtitle: 'Adicione produtos para continuar.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.read(cartProvider.notifier).loadCart(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Container(
                            color: context.surfaceColor,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  color: context.surfaceMidColor,
                                  child: item.product.imageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: item.product.imageUrl!,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 200,
                                          memCacheHeight: 200,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: context.surfaceMidColor,
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.image_outlined),
                                        )
                                      : const Icon(Icons.image_outlined),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
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
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyUtils.formatCents(
                                          item.product.price,
                                        ),
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Spacing.vSm,
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove,
                                              size: 16,
                                            ),
                                            onPressed: item.quantity > 1
                                                ? () => ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .updateQuantity(
                                                        item.productId,
                                                        item.quantity - 1,
                                                      )
                                                : null,
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              size: 16,
                                            ),
                                            onPressed: item.quantity < 10
                                                ? () => ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .updateQuantity(
                                                        item.productId,
                                                        item.quantity + 1,
                                                      )
                                                : null,
                                          ),
                                          const Spacer(),
                                          Text(
                                            CurrencyUtils.formatCents(
                                              item.subtotal,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () async {
                                    final notifier = ref.read(
                                      cartProvider.notifier,
                                    );
                                    final quantity = item.quantity;
                                    await notifier.removeFromCart(
                                      item.productId,
                                    );
                                    if (!context.mounted) return;
                                    AppSnackbar.undoable(
                                      context,
                                      message: 'Item removido do carrinho.',
                                      onUndo: () => notifier.addToCart(
                                        item.productId,
                                        quantity: quantity,
                                      ),
                                      onCommit: () {},
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: context.surfaceColor,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            CurrencyUtils.formatCents(cart.totalPrice),
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
                      label: 'CONTINUAR',
                      onPressed: hasUnavailableItems
                          ? null
                          : () => context.push(AppRoutes.checkoutCart),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
