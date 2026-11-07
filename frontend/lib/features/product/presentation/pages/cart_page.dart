import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/utils/media_url.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  @override
  void initState() {
    super.initState();
    ref.read(cartProvider.notifier).loadCart();
  }

  Future<void> _confirmClear(BuildContext context) async {
    final strings = l10n(context);
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: strings.commonClear,
      subtitle: strings.cartTitleCount(ref.read(cartProvider).cart.totalItems),
      customActions: [
        BrutalistDialogAction(
          text: strings.commonCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        BrutalistDialogAction(
          text: strings.commonClear,
          isDestructiveAction: true,
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref.read(cartProvider.notifier).clearCart();
    if (!context.mounted || !ok) return;
    AppSnackbar.info(context, strings.cartCleared);
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final state = ref.watch(cartProvider);
    final cart = state.cart;
    final hasUnavailableItems = cart.items.any(
      (item) =>
          item.product.status != ProductStatus.active ||
          item.quantity > item.product.quantity - item.product.soldCount,
    );
    final hasRemovedProducts = cart.items.any(
      (item) => item.product.status != ProductStatus.active,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.cartTitleCount(cart.totalItems),
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
              actions: [
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: () => _confirmClear(context),
                    child: Text(
                      strings.commonClear,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasRemovedProducts)
              Container(
                margin: const EdgeInsets.only(
                  left: Spacing.md,
                  top: Spacing.md,
                  right: Spacing.md,
                ),
                padding: const EdgeInsets.all(Spacing.md),
                color: context.surfaceMidColor,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.productUnavailable,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: state.isLoading && cart.items.isEmpty
                  ? const SkeletonPage(
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          ShimmerBlock(height: 80),
                          SizedBox(height: 12),
                          ShimmerBlock(height: 80),
                        ],
                      ),
                    )
                  : state.error != null && cart.items.isEmpty
                  ? EmptyState.error(
                      message: localizedFailureMessage(context, state.error),
                      onRetry: () => ref.read(cartProvider.notifier).loadCart(),
                    )
                  : cart.items.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: strings.cartEmptyTitle,
                      subtitle: strings.cartEmptyBody,
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.read(cartProvider.notifier).loadCart(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          final isUpdating = state.pendingProductIds.contains(
                            item.productId,
                          );
                          return Container(
                            color: context.surfaceColor,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  color: context.surfaceMidColor,
                                  child: item.product.imageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: item.product.imageUrl!,
                                          httpHeaders: mediaAuthHeaders(
                                            item.product.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                          memCacheWidth: 200,
                                          memCacheHeight: 200,
                                          placeholder: (context, url) =>
                                              BlurHashPlaceholder(
                                                hash: isPrivateMedia(url)
                                                    ? null
                                                    : item
                                                          .product
                                                          .imageBlurHash,
                                                fallback: Container(
                                                  color:
                                                      context.surfaceMidColor,
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.image_outlined),
                                        )
                                      : const Icon(Icons.image_outlined),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.status !=
                                                ProductStatus.active
                                            ? strings.cartProductUnavailable(
                                                item.product.title,
                                              )
                                            : item.quantity >
                                                  item.product.quantity -
                                                      item.product.soldCount
                                            ? strings.cartInsufficientStock(
                                                item.product.title,
                                              )
                                            : item.product.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyUtils.formatCents(
                                          item.product.price,
                                        ),
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Spacing.vSm,
                                      Row(
                                        children: [
                                          BrutalistIconButton(
                                            icon: Icons.remove,
                                            semanticLabel: strings
                                                .accessibilityDecreaseQuantity(
                                                  item.product.title,
                                                ),
                                            size: 24,
                                            onTap:
                                                item.quantity > 1 && !isUpdating
                                                ? () => ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .updateQuantity(
                                                        item.productId,
                                                        item.quantity - 1,
                                                      )
                                                : null,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                          ),
                                          BrutalistIconButton(
                                            icon: Icons.add,
                                            semanticLabel: strings
                                                .accessibilityIncreaseQuantity(
                                                  item.product.title,
                                                ),
                                            size: 24,
                                            onTap:
                                                item.quantity < 10 &&
                                                    item.quantity <
                                                        item.product.quantity -
                                                            item
                                                                .product
                                                                .soldCount &&
                                                    !isUpdating
                                                ? () => ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .updateQuantity(
                                                        item.productId,
                                                        item.quantity + 1,
                                                      )
                                                : null,
                                          ),
                                          const Spacer(),
                                          Text(
                                            CurrencyUtils.formatCents(
                                              item.subtotal,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                BrutalistIconButton(
                                  icon: Icons.close,
                                  semanticLabel: strings
                                      .accessibilityRemoveCartItem(
                                        item.product.title,
                                      ),
                                  size: 24,
                                  onTap: () async {
                                    final notifier = ref.read(
                                      cartProvider.notifier,
                                    );
                                    final quantity = item.quantity;
                                    await notifier.removeFromCart(
                                      item.productId,
                                    );
                                    if (!context.mounted) return;
                                    AppSnackbar.undoable(
                                      context,
                                      message: strings.cartItemRemoved,
                                      onUndo: () => notifier.addToCart(
                                        item.productId,
                                        quantity: quantity,
                                      ),
                                      onCommit: () {},
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (state.error != null && cart.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  localizedFailureMessage(context, state.error),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomSheet: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: context.surfaceColor,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.commonTotal,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            CurrencyUtils.formatCents(cart.totalPrice),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: strings.cartContinue,
                      onPressed: hasUnavailableItems
                          ? null
                          : () => context.push(AppRoutes.checkoutCart),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
