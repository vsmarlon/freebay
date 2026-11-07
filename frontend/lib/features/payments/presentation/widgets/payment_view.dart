import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/widgets/platform_wallet_payment_button.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PaymentSectionLabel extends StatelessWidget {
  final String text;

  const PaymentSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.colors.primary,
      ),
    );
  }
}

class PaymentView extends StatelessWidget {
  final ProductEntity product;
  final PaymentEntity? payment;
  final String? paymentIntentClientSecret;
  final String? createdOrderId;
  final int? amountCents;

  const PaymentView({
    super.key,
    required this.product,
    required this.payment,
    required this.paymentIntentClientSecret,
    required this.createdOrderId,
    this.amountCents,
  });

  Future<void> _openCheckout(BuildContext context) async {
    final uri = Uri.parse(payment!.checkoutUrl);
    if (uri.scheme != 'https' || uri.host != 'checkout.stripe.com') {
      AppSnackbar.error(context, l10n(context).paymentOpenFailed);
      return;
    }
    final launched = await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      AppSnackbar.error(context, l10n(context).paymentOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final isDark = context.isDark;
    final expiresAt = payment == null
        ? null
        : DateFormat.yMd(
            Localizations.localeOf(context).toString(),
          ).add_Hm().format(payment!.expiresAt.toLocal());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainer,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.paymentGenerated.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              if (payment != null) ...[
                Spacing.vSm,
                Text(
                  strings.paymentExpiresAt(expiresAt!),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: isDark
                        ? AppColors.inverseOnSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Spacing.vLg,
        if (payment != null) ...[
          PaymentSectionLabel(strings.paymentStripeCheckout.toUpperCase()),
          const SizedBox(height: 12),
          Container(
            color: isDark
                ? AppColors.surfaceContainerLowDark
                : AppColors.surfaceContainerLowest,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              payment!.checkoutUrl,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                height: 1.5,
                color: context.textPrimary,
              ),
            ),
          ),
          Spacing.vMd,
          AppButton(
            label: strings.paymentPayNow,
            onPressed: () => _openCheckout(context),
          ),
        ] else if (paymentIntentClientSecret != null) ...[
          PlatformWalletPaymentButton(
            clientSecret: paymentIntentClientSecret!,
            amountCents: amountCents ?? 0,
            itemLabel: product.title,
            onSubmitted: () {
              if (createdOrderId != null) {
                context.go(AppRoutes.orderPath(createdOrderId!));
              }
            },
          ),
        ],
        const SizedBox(height: 12),
        AppButton(
          label: strings.paymentViewOrder,
          onPressed: createdOrderId == null
              ? null
              : () => context.go(AppRoutes.orderPath(createdOrderId!)),
        ),
      ],
    );
  }
}
