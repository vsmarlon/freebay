import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/payments/data/entities/payment_entity.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

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

  const PaymentView({
    super.key,
    required this.product,
    required this.payment,
    required this.paymentIntentClientSecret,
    required this.createdOrderId,
  });

  Future<void> _openCheckout(BuildContext context) async {
    final uri = Uri.parse(payment!.checkoutUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    if (!launched && context.mounted) {
      AppSnackbar.error(context, 'Nao foi possivel abrir o checkout');
    }
  }

  Future<void> _presentPaymentSheet(BuildContext context) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret!,
          merchantDisplayName: 'FreeBay',
          returnURL: 'flutterstripe://redirect',
          style: ThemeMode.system,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      if (!context.mounted) return;
      AppSnackbar.success(
        context,
        'Pagamento enviado! Estamos confirmando com o provedor.',
      );
      if (createdOrderId != null) {
        context.go(AppRoutes.orderPath(createdOrderId!));
      }
    } on StripeException catch (e) {
      if (!context.mounted) return;
      if (e.error.code == FailureCode.Canceled) {
        AppSnackbar.info(context, 'Pagamento cancelado');
      } else {
        AppSnackbar.error(
          context,
          e.error.localizedMessage ?? 'Falha no pagamento',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final String? expiresAt = payment == null
        ? null
        : '${payment!.expiresAt.day.toString().padLeft(2, '0')}/${payment!.expiresAt.month.toString().padLeft(2, '0')} ${payment!.expiresAt.hour.toString().padLeft(2, '0')}:${payment!.expiresAt.minute.toString().padLeft(2, '0')}';

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
                'PAGAMENTO GERADO',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.onPrimaryContainer
                      : AppColors.primary,
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
                  'Expira em $expiresAt',
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
          const PaymentSectionLabel('CHECKOUT STRIPE'),
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
            label: 'Pagar agora',
            onPressed: () => _openCheckout(context),
          ),
        ] else if (paymentIntentClientSecret != null) ...[
          AppButton(
            label: 'Pagar com cartão',
            onPressed: () => _presentPaymentSheet(context),
          ),
        ],
        const SizedBox(height: 12),
        AppButton(
          label: 'Ver pedido',
          onPressed: createdOrderId == null
              ? null
              : () => context.go(AppRoutes.orderPath(createdOrderId!)),
        ),
      ],
    );
  }
}
