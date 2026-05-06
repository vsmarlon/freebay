import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freebay/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productAsync = ref.watch(productByIdProvider(productId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: productAsync.when(
        data: (product) => _buildContent(context, ref, product, isDark),
        loading: () => _buildLoadingSkeleton(context, isDark),
        error: (err, _) => _buildError(context, ref, err, isDark),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ProductEntity product, bool isDark) {
    final priceFormatted = CurrencyUtils.formatCents(product.price);
    final conditionLabel = product.condition == 'NEW' ? 'NOVO' : 'USADO';
    final favoriteAsync = ref.watch(isFavoritedProvider(product.id));
    final wishlistAsync = ref.watch(isInWishlistProvider(product.id));
    final favoritesState = ref.watch(favoritesProvider);
    final wishlistState = ref.watch(wishlistProvider);
    final isFavorited = favoritesState.isFavorited(product.id) || (favoriteAsync.value ?? false);
    final isInWishlist = wishlistState.isInWishlist(product.id) || (wishlistAsync.value ?? false);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurpleLight,
                                AppColors.accentGreenLight
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.photo_library,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('1', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black38 : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share,
                      color: isDark ? Colors.white : Colors.black),
                ),
                onPressed: () async {
                  final url = 'https://freebay.app/products/${product.id}';
                  await Share.share(
                    'Confira este produto no FreeBay: ${product.title}\n$url',
                    subject: product.title,
                  );
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isInWishlist ? Icons.bookmark : Icons.bookmark_border,
                    color: isInWishlist
                        ? AppColors.primaryPurple
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                onPressed: () async {
                  final ok = await ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
                  if (!context.mounted) {
                    return;
                  }
                  if (!ok) {
                    AppSnackbar.error(context, 'Não foi possível atualizar a wishlist');
                    return;
                  }
                  final nowInWishlist = ref.read(wishlistProvider).isInWishlist(product.id);
                  AppSnackbar.success(
                    context,
                    nowInWishlist
                        ? 'Produto adicionado à wishlist'
                        : 'Produto removido da wishlist',
                  );
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited
                        ? AppColors.error
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                onPressed: () async {
                  final ok = await ref.read(favoritesProvider.notifier).toggleFavorite(product.id);
                  if (!context.mounted) {
                    return;
                  }
                  if (!ok) {
                    AppSnackbar.error(context, 'Não foi possível atualizar favoritos');
                    return;
                  }
                  final nowFavorited = ref.read(favoritesProvider).isFavorited(product.id);
                  AppSnackbar.success(
                    context,
                    nowFavorited
                        ? 'Produto adicionado aos favoritos'
                        : 'Produto removido dos favoritos',
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withAlpha(25),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          conditionLabel,
                          style: const TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    priceFormatted,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                      color: isDark
                          ? AppColors.accentGreenLight
                          : AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pagamento via PIX com custódia até a confirmação do pedido.',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: isDark
                          ? AppColors.white.withAlpha(204)
                          : AppColors.darkGray.withAlpha(204),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: isDark
                        ? AppColors.mediumGray.withAlpha(50)
                        : AppColors.lightGray,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryPurple.withAlpha(25),
                        child: const Icon(Icons.person,
                            color: AppColors.primaryPurple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  product.sellerName ?? 'Vendedor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.darkGray,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Ver perfil do vendedor',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.mediumGray
                                    : AppColors.mediumGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push('/user/${product.sellerId}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.lightGray,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: AppColors.primaryPurple,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Ver perfil',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
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
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final ok = await ref
                        .read(cartProvider.notifier)
                        .addToCart(product.id, quantity: 1);
                    if (!context.mounted) {
                      return;
                    }
                    if (!ok) {
                      final error = ref.read(cartProvider).error;
                      AppSnackbar.error(
                        context,
                        error ?? 'Não foi possível adicionar ao carrinho',
                      );
                      return;
                    }
                    AppSnackbar.success(context, 'Produto adicionado ao carrinho');
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.lightGray,
                      border: Border.all(
                        color: AppColors.onSurface,
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Adicionar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
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
                  onPressed: () {
                    context.push('/profile/payment?productId=${product.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: isDark
                  ? AppColors.mediumGray.withAlpha(50)
                  : AppColors.lightGray,
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black38 : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 24,
                  width: 200,
                  color: isDark
                      ? AppColors.mediumGray.withAlpha(50)
                      : AppColors.lightGray,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 32,
                  width: 120,
                  color: isDark
                      ? AppColors.mediumGray.withAlpha(50)
                      : AppColors.lightGray,
                ),
                const SizedBox(height: 24),
                Container(
                  height: 100,
                  color: isDark
                      ? AppColors.mediumGray.withAlpha(50)
                      : AppColors.lightGray,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(
      BuildContext context, WidgetRef ref, Object err, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? AppColors.error : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar produto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'SpaceGrotesk',
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: AppColors.mediumGray,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Voltar',
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => ref.invalidate(productByIdProvider(productId)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Text(
                      'Tentar novamente',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
