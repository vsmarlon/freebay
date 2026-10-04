import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freebay/core/router/app_routes.dart';

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
    final strings = l10n(context);
    final isDark = context.isDark;
    final state = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.profileFavoritesTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.commonBack,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(favoritesProvider.notifier).loadFavorites(),
                child: state.isLoading
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: 6,
                        itemBuilder: (context, index) =>
                            const AppCard.skeleton(),
                      )
                    : state.products.isEmpty
                    ? EmptyState(
                        icon: Icons.favorite_border,
                        title: strings.profileNoFavorites,
                        subtitle: strings.profileFavoritesEmpty,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  imageBlurHash: product.imageBlurHash,
                                  variant: AppCardVariant.compact,
                                  onTap: () => context.push(
                                    AppRoutes.productPath(product.id),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ref
                                        .read(favoritesProvider.notifier)
                                        .toggleFavorite(product.id);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.white,
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
            ),
          ],
        ),
      ),
    );
  }
}
