import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:share_plus/share_plus.dart';
import 'package:freebay/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/widgets/escrow_trust_banner.dart';
import 'package:freebay/features/product/presentation/widgets/product_detail_bottom_sheet.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/utils/media_url.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final productAsync = ref.watch(productByIdProvider(productId));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: productAsync.when(
        data: (product) => _buildContent(context, ref, product),
        loading: () => const SkeletonPage(
          child: Column(
            children: [
              SizedBox(height: 16),
              ShimmerBlock(height: 200),
              SizedBox(height: 16),
              ShimmerBlock(height: 40),
            ],
          ),
        ),
        error: (err, _) => EmptyState.error(
          message: strings.productLoadError,
          onRetry: () => ref.invalidate(productByIdProvider(productId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
  ) {
    final strings = l10n(context);
    final priceFormatted = CurrencyUtils.formatCents(product.price);
    final isFavorited =
        ref.watch(isFavoritedProvider(product.id)).value ??
        ref.watch(favoritesProvider).isFavorited(product.id);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.surfaceColor,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? GestureDetector(
                      onTap: () => unawaited(
                        showAppImageViewer(context, product.imageUrl!),
                      ),
                      child: Hero(
                        tag: 'product-image-${product.id}',
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          httpHeaders: mediaAuthHeaders(product.imageUrl!),
                          memCacheWidth:
                              (MediaQuery.sizeOf(context).width *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .ceil()
                                  .clamp(1, 1080),
                          placeholder: (context, url) => BlurHashPlaceholder(
                            hash: product.imageBlurHash,
                            fallback: Container(color: context.surfaceMidColor),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: context.surfaceMidColor,
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 64,
                                color: AppColors.mediumGray,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: context.surfaceMidColor,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ),
            ),
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              semanticLabel: strings.commonBack,
              onTap: () => Navigator.pop(context),
              iconColor: context.textPrimary,
              borderColor: context.borderColor,
            ),
            actions: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BrutalistIconButton(
                    icon: Icons.shopping_cart_outlined,
                    semanticLabel: strings.productCartLabel(cartItemCount),
                    borderColor: context.borderColor,
                    onTap: () => context.push(AppRoutes.cart),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        color: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$cartItemCount',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              BrutalistIconButton(
                icon: isFavorited ? Icons.favorite : Icons.favorite_border,
                semanticLabel: isFavorited
                    ? strings.productFavoriteRemove
                    : strings.productFavoriteAdd,
                iconColor: isFavorited ? AppColors.error : context.textPrimary,
                borderColor: context.borderColor,
                onTap: () async {
                  await ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(product.id);
                  ref.invalidate(isFavoritedProvider(product.id));
                },
              ),
              const SizedBox(width: 8),
              BrutalistIconButton(
                icon: Icons.share,
                semanticLabel: strings.commonShare,
                borderColor: context.borderColor,
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text: strings.productShareMessage(
                      product.title,
                      'https://freebay.app/products/${product.id}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                      fontWeight: FontWeight.w900,
                      color: context.textPrimary,
                    ),
                  ),
                  Spacing.vSm,
                  Row(
                    children: [
                      Text(
                        priceFormatted,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.condition == ProductCondition.isNew
                              ? AppColors.primaryContainer.withAlpha(30)
                              : context.surfaceMidColor,
                          border: Border.all(
                            color: product.condition == ProductCondition.isNew
                                ? AppColors.primaryContainer
                                : context.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          product.condition == ProductCondition.isNew
                              ? strings.productConditionNew
                              : strings.productConditionUsed,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: product.condition == ProductCondition.isNew
                                ? AppColors.primaryContainer
                                : context.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.vMd,
                  const EscrowTrustBanner(),
                  Spacing.vMd,
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      border: Border.all(
                        color: context.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          imageUrl: product.seller?.avatarUrl,
                          blurHash: product.seller?.avatarBlurHash,
                        ),
                        Spacing.hSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.seller?.displayName ??
                                    strings.productSeller,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              if (product.seller?.username?.isNotEmpty == true)
                                Text(
                                  '@${product.seller!.username!}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (product.seller != null)
                          TextButton.icon(
                            onPressed: () => context.push(
                              AppRoutes.chatNewWith(
                                product.seller!.id,
                                product.id,
                              ),
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                            ),
                            label: Text(strings.productChatWithSeller),
                          ),
                      ],
                    ),
                  ),
                  Spacing.vMd,
                  Text(
                    strings.productDescription.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                    ),
                  ),
                  Spacing.vSm,
                  Text(
                    product.description.isEmpty
                        ? strings.productNoDescription
                        : product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: ProductDetailBottomSheet(product: product),
    );
  }
}
