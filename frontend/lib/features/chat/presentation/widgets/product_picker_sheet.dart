import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';

/// Shows a bottom sheet for picking a product to share as a PRODUCT_CARD message.
Future<void> showProductPickerSheet({
  required BuildContext context,
  required void Function(Map<String, dynamic> metadata) onProductSelected,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ProductPickerSheet(onProductSelected: onProductSelected),
  );
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic> metadata) onProductSelected;

  const _ProductPickerSheet({required this.onProductSelected});

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(myProductsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: context.bgColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 2)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 32,
            height: 4,
            color: context.textSecondary,
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'ESCOLHER PRODUTO',
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: context.isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.lightGray,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.outline),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: AppColors.primaryContainer,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 16),
          // Product list
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: ShimmerBlock(width: 200, height: 40)),
              error: (err, _) => Center(
                child: Text(
                  'Erro ao carregar produtos',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum produto encontrado',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                final filtered = _searchQuery.isEmpty
                    ? products
                    : products
                          .where(
                            (p) => p.title.toLowerCase().contains(_searchQuery),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum produto encontrado',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final product = filtered[i];
                    return _ProductPickerItem(
                      product: product,
                      onTap: () {
                        widget.onProductSelected({
                          'productId': product.id,
                          'title': product.title,
                          'price': product.price,
                          'imageUrl': product.imageUrl,
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPickerItem extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const _ProductPickerItem({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceStr = 'R\$ ${(product.price / 100).toStringAsFixed(2)}';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceStr,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.mediumGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 20,
          color: AppColors.mediumGray,
        ),
      ),
    );
  }
}
