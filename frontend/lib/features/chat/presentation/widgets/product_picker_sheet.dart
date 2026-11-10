import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Shows a bottom sheet for picking a product to share as a PRODUCT_CARD message.
Future<void> showProductPickerSheet({
  required BuildContext context,
  required void Function(Map<String, dynamic> metadata) onProductSelected,
}) {
  return showBrutalistSheet<void>(
    context: context,
    title: l10n(context).chatChooseProduct.toUpperCase(),
    padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
    scrollable: false,
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
    final strings = l10n(context);
    final productsAsync = ref.watch(myProductsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input
        AppTextField(
          controller: _searchController,
          hint: strings.chatSearchProductHint,
          prefixIcon: Icons.search,
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase()),
        ),
        const SizedBox(height: 16),
        // Product list
        Expanded(
          child: productsAsync.when(
            loading: () =>
                const Center(child: ShimmerBlock(width: 200, height: 40)),
            error: (err, _) => Center(
              child: Text(
                strings.errorUnknown,
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            ),
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Text(
                    strings.productNoProductsBody,
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
                    strings.productNoProductsBody,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
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
          border: Border(bottom: BorderSide(color: context.borderColor)),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      httpHeaders: mediaAuthHeaders(product.imageUrl!),
                      fit: BoxFit.cover,
                      memCacheWidth: 140,
                      memCacheHeight: 140,
                      placeholder: (context, url) => BlurHashPlaceholder(
                        hash: isPrivateMedia(url)
                            ? null
                            : product.imageBlurHash,
                        fallback: _buildPlaceholder(),
                      ),
                      errorWidget: (_, _, _) => _buildPlaceholder(),
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
                    style: const TextStyle(
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
