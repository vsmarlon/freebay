import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/core/router/navigation_tracker.dart';

class MyProductsPage extends ConsumerWidget {
  const MyProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final productsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'MEUS ANÚNCIOS',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: context.textPrimary),
                onPressed: () => context.push(AppRoutes.createProduct),
              ),
            ],
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                return Column(
                  children: [
                    BrutalistBreadcrumb(items: context.breadcrumbs),
                    Expanded(
                      child: products.isEmpty
                          ? EmptyState(
                              icon: Icons.shopping_bag_outlined,
                              title: 'NENHUM AN\u00daNCIO',
                              subtitle: 'Nenhum an\u00fancio ainda',
                              action: AppButton(
                                label: 'Criar an\u00fancio',
                                icon: Icons.add,
                                onPressed: () =>
                                    context.push(AppRoutes.createProduct),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(myProductsProvider);
                              },
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.75,
                                    ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return _buildProductCard(
                                    context,
                                    product,
                                    isDark,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: 6,
                itemBuilder: (_, _) => const AppCard.skeleton(),
                physics: const NeverScrollableScrollPhysics(),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    Spacing.vMd,
                    Text(
                      'Erro ao carregar an\u00fancios',
                      style: TextStyle(color: context.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductEntity product,
    bool isDark,
  ) {
    final price = product.price > 0 ? product.price / 100 : 0.0;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.productPath(product.id)),
      child: Container(
        decoration: BoxDecoration(
          color: context.bgColor,
          border: Border.all(
            color: AppColors.onSurface.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.lightGray,
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        memCacheHeight: 400,
                        placeholder: (context, url) => Container(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.lightGray,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.shopping_bag,
                          color: AppColors.mediumGray,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag,
                        color: AppColors.mediumGray,
                        size: 40,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  Spacing.vXs,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      _buildStatusBadge(product.status, isDark),
                    ],
                  ),
                  Spacing.vSm,
                  InkWell(
                    onTap: () =>
                        context.push(AppRoutes.productEditPath(product.id)),
                    child: Container(
                      width: double.infinity,
                      height: 36,
                      color: isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerHighest,
                      child: const Center(
                        child: Text(
                          'Editar anúncio',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
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

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'ACTIVE':
        bgColor = AppColors.success.withValues(alpha: 0.2);
        textColor = AppColors.success;
        break;
      case 'PAUSED':
        bgColor = AppColors.warning.withValues(alpha: 0.2);
        textColor = AppColors.warning;
        break;
      case 'SOLD':
        bgColor = AppColors.mediumGray.withValues(alpha: 0.2);
        textColor = AppColors.mediumGray;
        break;
      default:
        bgColor = AppColors.mediumGray.withValues(alpha: 0.2);
        textColor = AppColors.mediumGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
