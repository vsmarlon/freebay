import 'package:freebay/core/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/core/router/app_routes.dart';

const _crossAxisCount = 2;
const _childAspectRatio = 0.68;
const _gridSpacing = 14.0;
const _skeletonCount = 6;
const _loadingMoreSkeletonCount = 2;

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: _crossAxisCount,
  childAspectRatio: _childAspectRatio,
  crossAxisSpacing: _gridSpacing,
  mainAxisSpacing: _gridSpacing,
);

class ProductResultsGrid extends StatelessWidget {
  final List<ProductEntity> products;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const ProductResultsGrid({
    super.key,
    required this.products,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  const ProductResultsGrid.skeleton({super.key})
    : products = const [],
      isLoadingMore = false,
      onLoadMore = _noop;

  static void _noop() {}

  bool get _isSkeleton => products.isEmpty && !isLoadingMore;

  @override
  Widget build(BuildContext context) {
    if (_isSkeleton) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: _gridDelegate,
        itemCount: _skeletonCount,
        itemBuilder: (context, index) => const AppCard.skeleton(),
      );
    }

    return InfiniteScrollListener(
      onLoadMore: onLoadMore,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: _gridDelegate,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount:
            products.length + (isLoadingMore ? _loadingMoreSkeletonCount : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) return const AppCard.skeleton();
          final product = products[index];
          return RepaintBoundary(
            child: AppCard(
              imageUrl: product.imageUrl,
              title: product.title,
              priceInCents: product.price,
              condition: product.condition.wireValue,
              variant: AppCardVariant.compact,
              onTap: () => context.push(AppRoutes.productPath(product.id)),
            ),
          );
        },
      ),
    );
  }
}
