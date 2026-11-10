import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/shared/services/payment_sdk_service.dart';

class PlatformWalletPaymentButton extends StatelessWidget {
  const PlatformWalletPaymentButton({
    super.key,
    required this.clientSecret,
    required this.amountCents,
    required this.itemLabel,
    required this.onSubmitted,
  });

  final String clientSecret;
  final int amountCents;
  final String itemLabel;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: PaymentSdkService.isWalletAvailable(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox.shrink();
      }
      if (snapshot.data != true) {
        return Text(
          l10n(context).paymentWalletUnavailable,
          style: AppTypography.bodySmall.copyWith(color: context.textSecondary),
        );
      }
      return PlatformPayButton(
        type: PlatformButtonType.buy,
        onPressed: () => _pay(context),
      );
    },
  );

  Future<void> _pay(BuildContext context) async {
    try {
      await PaymentSdkService.confirmWalletPayment(
        clientSecret: clientSecret,
        amountCents: amountCents,
        itemLabel: itemLabel,
      );
      if (!context.mounted) return;
      AppSnackbar.success(context, l10n(context).paymentSubmittedPending);
      onSubmitted();
    } on StripeException catch (error, stack) {
      if (error.error.code == FailureCode.Canceled) {
        if (context.mounted) {
          AppSnackbar.info(context, l10n(context).paymentCancelled);
        }
        return;
      }
      ErrorReporter.report(
        'platform-wallet-payment',
        StateError(
          'Stripe ${error.error.code.name}: ${error.error.stripeErrorCode ?? 'unknown'}',
        ),
        stack,
      );
      if (context.mounted) AppSnackbar.handleFailure(context, error);
    } catch (error, stack) {
      ErrorReporter.report(
        'platform-wallet-payment',
        StateError('Platform wallet ${error.runtimeType}'),
        stack,
      );
      if (context.mounted) AppSnackbar.handleFailure(context, error);
    }
  }
}
