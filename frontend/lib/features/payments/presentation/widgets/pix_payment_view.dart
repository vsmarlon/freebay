import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/features/payments/data/entities/pix_payment_entity.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

class PaymentSectionLabel extends StatelessWidget {
  final String text;

  const PaymentSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
      ),
    );
  }
}

class PixPaymentView extends StatelessWidget {
  final ProductEntity product;
  final PixPaymentEntity pixPayment;
  final String? createdOrderId;

  const PixPaymentView({
    super.key,
    required this.product,
    required this.pixPayment,
    required this.createdOrderId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final expiresAt =
        '${pixPayment.expiresAt.day.toString().padLeft(2, '0')}/${pixPayment.expiresAt.month.toString().padLeft(2, '0')} ${pixPayment.expiresAt.hour.toString().padLeft(2, '0')}:${pixPayment.expiresAt.minute.toString().padLeft(2, '0')}';

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
                'PIX GERADO',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.onPrimaryContainer : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.title,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
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
          ),
        ),
        Spacing.vLg,
        const PaymentSectionLabel('CODIGO PIX'),
        const SizedBox(height: 12),
        Container(
          color: isDark
              ? AppColors.surfaceContainerLowDark
              : AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            pixPayment.pixQrCode,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
        ),
        Spacing.vMd,
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: pixPayment.pixQrCode));
            if (!context.mounted) {
              return;
            }
            AppSnackbar.success(context, 'Codigo PIX copiado');
          },
          child: Container(
            width: double.infinity,
            height: 48,
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerHighest,
            child: Center(
              child: Text(
                'Copiar codigo',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Ver pedido',
          onPressed: createdOrderId == null
              ? null
              : () => context.go('/orders/${createdOrderId!}'),
        ),
      ],
    );
  }
}
