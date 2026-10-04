import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/error_reporter.dart';

class PaymentSdkService {
  static Future<void>? _initialization;

  static Future<void> ensureReady() => _initialization ??= _initialize();

  static Future<void> _initialize() async {
    if (kIsWeb || AppConfig.stripePublishableKey.isEmpty) return;
    try {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      if (AppConfig.applePayMerchantId.isNotEmpty) {
        Stripe.merchantIdentifier = AppConfig.applePayMerchantId;
      }
      await Stripe.instance.applySettings();
    } catch (error, stack) {
      ErrorReporter.report('stripe-init', error, stack);
    }
  }

  static bool get hasWalletConfiguration {
    if (AppConfig.stripePublishableKey.isEmpty) return false;
    final country = AppConfig.paymentMerchantCountryCode;
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(country)) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        AppConfig.applePayMerchantId.isEmpty) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (kReleaseMode) {
        if (!AppConfig.googlePayProductionEnabled ||
            AppConfig.googlePayTestEnvironment) {
          return false;
        }
      } else if (!AppConfig.googlePayTestEnvironment) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> isWalletAvailable() async {
    if (kIsWeb || !hasWalletConfiguration) return false;
    try {
      await ensureReady();
      return await Stripe.instance.isPlatformPaySupported(
        googlePay: IsGooglePaySupportedParams(
          testEnv: _googlePayTestEnvironment,
        ),
      );
    } catch (error, stack) {
      ErrorReporter.report('wallet-availability', error, stack);
      return false;
    }
  }

  static Future<void> confirmWalletPayment({
    required String clientSecret,
    required int amountCents,
    required String itemLabel,
  }) async {
    if (!hasWalletConfiguration || amountCents <= 0) {
      throw StateError('Wallet payment is not configured');
    }
    await ensureReady();
    final country = AppConfig.paymentMerchantCountryCode;
    final params = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => PlatformPayConfirmParams.applePay(
        applePay: ApplePayParams(
          merchantCountryCode: country,
          currencyCode: 'BRL',
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: itemLabel,
              amount: _formatBrlCents(amountCents),
            ),
          ],
        ),
      ),
      TargetPlatform.android => PlatformPayConfirmParams.googlePay(
        googlePay: GooglePayParams(
          testEnv: _googlePayTestEnvironment,
          merchantCountryCode: country,
          currencyCode: 'BRL',
          merchantName: 'FreeBay',
        ),
      ),
      _ => throw StateError('Platform wallet is unavailable'),
    };
    await Stripe.instance.confirmPlatformPayPaymentIntent(
      clientSecret: clientSecret,
      confirmParams: params,
    );
  }

  static String _formatBrlCents(int cents) =>
      '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

  static bool get _googlePayTestEnvironment =>
      AppConfig.googlePayTestEnvironment;
}
