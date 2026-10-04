import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/shared/widgets/platform_wallet_payment_button.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class CartCheckoutPage extends HookConsumerWidget {
  const CartCheckoutPage({super.key});

  Future<void> _submitCheckout(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(cartProvider.notifier).checkout();
    if (!ok && context.mounted) {
      AppSnackbar.error(context, l10n(context).cartCheckoutFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    useEffect(() {
      Future.microtask(() => ref.read(cartProvider.notifier).loadCart());
      return null;
    }, const []);
    final state = ref.watch(cartProvider);
    final cart = state.cart;
    final hasUnavailableItems = cart.items.any(
      (item) =>
          item.product.status != ProductStatus.active ||
          item.quantity > item.product.quantity - item.product.soldCount,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.cartCheckoutTitle.toUpperCase(),
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: state.lastCheckout != null
                  ? _buildResult(context, state.lastCheckout!)
                  : state.isLoading
                  ? const SkeletonPage(
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          ShimmerBlock(height: 80),
                          SizedBox(height: 12),
                          ShimmerBlock(height: 80),
                          SizedBox(height: 12),
                          ShimmerBlock(height: 80),
                        ],
                      ),
                    )
                  : state.error != null
                  ? EmptyState.error(
                      message: state.error!,
                      onRetry: () => ref.read(cartProvider.notifier).loadCart(),
                    )
                  : cart.items.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: strings.cartEmptyTitle.toUpperCase(),
                      subtitle: strings.cartEmptyBody,
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: cart.items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final item = cart.items[i];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                color: context.surfaceColor,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
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
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.quantity}x',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      CurrencyUtils.formatCents(item.subtotal),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: context.surfaceColor,
                          child: SafeArea(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        strings.cartTotalItems(cart.totalItems),
                                        style: TextStyle(
                                          color: context.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        CurrencyUtils.formatCents(
                                          cart.totalPrice,
                                        ),
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
                                  label: strings.cartGenerateCheckout,
                                  isLoading: state.isCheckingOut,
                                  onPressed: hasUnavailableItems
                                      ? null
                                      : () => _submitCheckout(context, ref),
                                ),
                              ],
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

  Widget _buildResult(BuildContext context, CartCheckoutEntity checkout) {
    final strings = l10n(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: context.surfaceColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.cartCheckoutGenerated.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
              Spacing.vSm,
              Text(
                strings.ordersCreatedCount(checkout.totalOrders),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              Spacing.vSm,
              Text(
                strings.cartTotalAmount(
                  CurrencyUtils.formatCents(checkout.totalAmount),
                ),
                style: TextStyle(fontSize: 16, color: context.textSecondary),
              ),
              Spacing.vMd,
              if (checkout.checkoutUrl case final url?) ...[
                AppButton(
                  label: strings.cartPayNow,
                  onPressed: () => _openCheckout(context, url),
                ),
                Spacing.vSm,
              ] else if (checkout.paymentIntentClientSecret
                  case final secret?) ...[
                PlatformWalletPaymentButton(
                  clientSecret: secret,
                  amountCents: checkout.totalAmount,
                  itemLabel: strings.cartCheckoutTitle,
                  onSubmitted: () {},
                ),
                Spacing.vSm,
              ],
              Text(
                strings.paymentProviderConfirmationNote,
                style: AppTypography.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              Spacing.vSm,
              AppButton(
                label: strings.cartViewOrders,
                onPressed: () => context.go(AppRoutes.orders),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openCheckout(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri?.scheme != 'https' || uri?.host != 'checkout.stripe.com') {
      AppSnackbar.error(context, l10n(context).paymentInvalidLink);
      return;
    }
    try {
      final launched = await launchUrl(uri!, mode: LaunchMode.inAppWebView);
      if (!launched && context.mounted) {
        AppSnackbar.error(context, l10n(context).paymentOpenFailed);
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, l10n(context).paymentOpenFailed);
      }
    }
  }
}
