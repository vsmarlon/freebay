import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_card.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/wishlist/presentation/providers/wishlist_provider.dart';

class WishlistPage extends ConsumerStatefulWidget {
  const WishlistPage({super.key});

  @override
  ConsumerState<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends ConsumerState<WishlistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistProvider.notifier).loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Lista de desejos'),
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
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlist(),
        child: state.isLoading
            ? GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const AppCard.skeleton(),
              )
            : state.products.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                      Icon(
                        Icons.bookmark_border,
                        size: 80,
                        color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sua wishlist está vazia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Salve produtos para comprar depois.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AppCard(
                              title: product.title,
                              priceInCents: product.price,
                              imageUrl: product.imageUrl,
                              variant: AppCardVariant.compact,
                              onTap: () => context.push('/products/${product.id}'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final ok = await ref
                                  .read(cartProvider.notifier)
                                  .addToCart(product.id, quantity: 1);
                              if (!context.mounted) {
                                return;
                              }
                              if (!ok) {
                                AppSnackbar.error(
                                  context,
                                  ref.read(cartProvider).error ??
                                      'Não foi possível adicionar ao carrinho',
                                );
                                return;
                              }
                              AppSnackbar.success(context, 'Adicionado ao carrinho');
                            },
                            child: Container(
                              height: 38,
                              color: AppColors.primaryContainer,
                              child: const Center(
                                child: Text(
                                  'Adicionar',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
                            },
                            child: Container(
                              height: 34,
                              color: isDark ? AppColors.surfaceContainerDark : AppColors.lightGray,
                              child: const Center(
                                child: Text(
                                  'Remover',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
