import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/page_header.dart';

final myProductsProvider = FutureProvider<List<ProductEntity>>((ref) async {
  final repository = ProductRepository();
  final result = await repository.getMyProducts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (products) => products,
  );
});

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
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
                onPressed: () => context.push('/products/create'),
              ),
            ],
          ),
          Expanded(
            child: productsAsync.when(
        data: (products) {
          return Column(
            children: [
              BrutalistBreadcrumb(items: [
                BreadcrumbItem(label: 'Perfil', onTap: () => context.pop()),
                const BreadcrumbItem(label: 'Meus An\u00fancios'),
              ]),
              Expanded(
                child: products.isEmpty
                    ? EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'NENHUM AN\u00daNCIO',
                        subtitle: 'Nenhum an\u00fancio ainda',
                        action: InkWell(
                          onTap: () => context.push('/products/create'),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: const BoxDecoration(
                              gradient: AppColors.brutalistGradient,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: AppColors.onPrimary),
                                Spacing.hSm,
                                Text(
                                  'Criar an\u00fancio',
                                  style: TextStyle(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(myProductsProvider);
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductCard(context, product, isDark);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              Spacing.vMd,
              Text(
                'Erro ao carregar an\u00fancios',
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
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
      BuildContext context, ProductEntity product, bool isDark) {
    final price = product.price > 0 ? product.price / 100 : 0.0;

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
        child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.15), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.backgroundDark : AppColors.lightGray,
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
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
                      color: isDark ? AppColors.white : AppColors.darkGray,
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
                    onTap: () => context.push('/products/${product.id}/edit'),
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
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.zero,
      ),
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
