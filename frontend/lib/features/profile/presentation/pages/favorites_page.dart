import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_card.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/favorites/presentation/providers/favorites_provider.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    ref.read(favoritesProvider.notifier).loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final state = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: context.appBarColor,
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
        onRefresh: () => ref.read(favoritesProvider.notifier).loadFavorites(),
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
                        Icons.favorite_border,
                        size: 80,
                        color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Você ainda não tem favoritos',
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
                        'Toque no coração dos produtos para salvar aqui.',
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
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: AppCard(
                              title: product.title,
                              priceInCents: product.price,
                              imageUrl: product.imageUrl,
                              variant: AppCardVariant.compact,
                              onTap: () => context.push('/products/${product.id}'),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref.read(favoritesProvider.notifier).toggleFavorite(product.id);
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                color: isDark ? AppColors.surfaceDark : AppColors.white,
                                child: const Icon(
                                  Icons.favorite,
                                  size: 18,
                                  color: AppColors.error,
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
