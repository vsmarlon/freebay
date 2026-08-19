import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay_design_system/tokens/app_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/full_screen_image_viewer.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:freebay/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/widgets/product_detail_bottom_sheet.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Erro ao carregar produto',
                style: TextStyle(color: context.textPrimary),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'TENTAR NOVAMENTE',
                size: AppButtonSize.compact,
                onPressed: () => ref.invalidate(productByIdProvider(productId)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
  ) {
    final priceFormatted = CurrencyUtils.formatCents(product.price);
    final isFavorited =
        ref.watch(isFavoritedProvider(product.id)).value ??
        ref.watch(favoritesProvider).isFavorited(product.id);

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
                      onTap: () =>
                          showFullScreenImage(context, product.imageUrl!),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 1080,
                        placeholder: (context, url) =>
                            Container(color: context.surfaceMidColor),
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
              onTap: () => Navigator.pop(context),
              iconColor: context.textPrimary,
              borderColor: context.borderColor,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? AppColors.error : context.textPrimary,
                ),
                onPressed: () async {
                  await ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(product.id);
                  ref.invalidate(isFavoritedProvider(product.id));
                },
              ),
              IconButton(
                icon: Icon(Icons.share, color: context.textPrimary),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Confira: ${product.title}\nhttps://freebay.app/products/${product.id}',
                  ),
                ),
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
                      fontWeight: FontWeight.w900,
                      color: context.textPrimary,
                    ),
                  ),
                  Spacing.vSm,
                  Row(
                    children: [
                      Text(
                        priceFormatted,
                        style: TextStyle(
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
                          color: product.condition.toUpperCase() == 'NEW'
                              ? const Color(0xFF8A1083).withAlpha(30)
                              : context.surfaceMidColor,
                          border: Border.all(
                            color: product.condition.toUpperCase() == 'NEW'
                                ? const Color(0xFF8A1083)
                                : context.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          product.condition.toUpperCase() == 'NEW'
                              ? 'NOVO'
                              : 'USADO',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: product.condition.toUpperCase() == 'NEW'
                                ? const Color(0xFF8A1083)
                                : context.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.vMd,
                  // Escrow Trust Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withAlpha(20),
                      border: Border.all(
                        color: AppColors.accentAmber,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.accentAmber,
                          size: 20,
                        ),
                        Spacing.hSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CUSTÓDIA FREEBAY GARANTIDA',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accentAmber,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Seu pagamento só é liberado para o vendedor após você receber o produto e confirmar a entrega.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          size: AppAvatarSize.medium,
                        ),
                        Spacing.hSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.seller?.displayName ?? 'Vendedor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                '@${product.seller?.username ?? 'usuario'}',
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
                              '/chat/new?userId=${product.seller!.id}',
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                            ),
                            label: const Text('Conversar'),
                          ),
                      ],
                    ),
                  ),
                  Spacing.vMd,
                  Text(
                    'DESCRIÇÃO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                    ),
                  ),
                  Spacing.vSm,
                  Text(
                    product.description.isEmpty
                        ? 'Sem descrição.'
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
