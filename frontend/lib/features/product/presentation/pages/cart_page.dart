import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(cartProvider);
    final cart = state.cart;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Carrinho (${cart.totalItems})'),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            InkWell(
              onTap: () async {
                final ok = await ref.read(cartProvider.notifier).clearCart();
                if (!context.mounted) {
                  return;
                }
                if (!ok) {
                  AppSnackbar.error(context, 'Não foi possível limpar o carrinho');
                  return;
                }
                AppSnackbar.info(context, 'Carrinho limpo');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Limpar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Seu carrinho está vazio',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Adicione produtos para continuar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () => context.go('/products'),
                        child: Container(
                          width: 180,
                          height: 44,
                          color: AppColors.primaryContainer,
                          child: const Center(
                            child: Text(
                              'Explorar produtos',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final price = CurrencyUtils.formatCents(item.product.price);
                    final subtotal = CurrencyUtils.formatCents(item.subtotal);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            color: isDark
                                ? AppColors.surfaceContainerDark
                                : AppColors.lightGray,
                            child: item.product.imageUrl != null
                                ? Image.network(item.product.imageUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.image_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.white : AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  price,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _QuantityButton(
                                      icon: Icons.remove,
                                      onTap: item.quantity > 1
                                          ? () => ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(item.productId, item.quantity - 1)
                                          : null,
                                    ),
                                    Container(
                                      width: 40,
                                      height: 28,
                                      color: isDark
                                          ? AppColors.surfaceContainerDark
                                          : AppColors.lightGray,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.white : AppColors.darkGray,
                                        ),
                                      ),
                                    ),
                                    _QuantityButton(
                                      icon: Icons.add,
                                      onTap: item.quantity < 10
                                          ? () => ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(item.productId, item.quantity + 1)
                                          : null,
                                    ),
                                    const Spacer(),
                                    Text(
                                      subtotal,
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.white : AppColors.darkGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                ref.read(cartProvider.notifier).removeFromCart(item.productId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomSheet: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppColors.surfaceDark : AppColors.white,
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
                              fontFamily: 'Inter',
                              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                            ),
                          ),
                          Text(
                            CurrencyUtils.formatCents(cart.totalPrice),
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.white : AppColors.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/checkout/cart'),
                        child: Container(
                          height: 48,
                          color: AppColors.primaryContainer,
                          child: const Center(
                            child: Text(
                              'Finalizar',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        color: onTap == null
            ? (isDark ? AppColors.surfaceContainerDark : AppColors.lightGray)
            : AppColors.primaryContainer,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? (isDark ? AppColors.mediumGray : AppColors.mediumGray)
              : AppColors.white,
        ),
      ),
    );
  }
}
