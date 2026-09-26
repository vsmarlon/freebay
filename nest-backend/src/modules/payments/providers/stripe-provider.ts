import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { CHECKOUT_EXPIRY_MILLISECONDS, CHECKOUT_EXPIRY_SECONDS } from '../payment.constants';
import { Either, left, right } from '@/shared/core/either';
import { AppError, PaymentProviderError } from '@/shared/core/errors';
import {
  PaymentIntentParams,
  PaymentIntentResult,
  PaymentSessionParams,
  PaymentSessionResult,
} from '../types/payment-provider.types';
import {
  ConnectAccountSnapshot,
  CreateConnectAccountParams,
  CreateTransferParams,
  TransferReconciliationParams,
  TransferReconciliationResult,
  ReversalReconciliationParams,
} from '../types/connect.types';
import { StripeConnectClient } from './stripe-connect-client';
import {
  StripeWebhookEvent,
  StripeWebhookVerifier,
} from './stripe-webhook-verifier';

export { StripeWebhookEvent, VerifiedV2AccountWebhookEvent } from './stripe-webhook-verifier';

@Injectable()
export class StripeProvider {
  private static readonly API_VERSION = '2026-07-29.dahlia';
  private readonly logger = new Logger(StripeProvider.name);
  private readonly stripe: Stripe;
  private readonly webhookSecret: string;
  private readonly connect: StripeConnectClient;
  private readonly webhookVerifier: StripeWebhookVerifier;

  constructor(private readonly config: ConfigService) {
    const key = this.config.get<string>('STRIPE_SECRET_KEY');
    if (!key) {
      throw new Error('STRIPE_SECRET_KEY is not configured');
    }
    if (!/^(sk|rk)_(test|live)_/.test(key)) {
      throw new Error('STRIPE_SECRET_KEY has an invalid prefix');
    }
    if (key.startsWith('sk_test_') || key.startsWith('rk_test_')) {
      const environment = this.config.get<string>('NODE_ENV');
      if (environment === 'production') {
        throw new Error('Stripe test keys are not allowed in production');
      }
    }
    const webhookSecret = this.config.get<string>('STRIPE_WEBHOOK_SECRET');
    if (!webhookSecret) {
      throw new Error('STRIPE_WEBHOOK_SECRET is not configured');
    }
    this.stripe = new Stripe(key, { apiVersion: StripeProvider.API_VERSION });
    this.webhookSecret = webhookSecret;
    this.connect = new StripeConnectClient(this.stripe, this.logger);
    this.webhookVerifier = new StripeWebhookVerifier(
      this.stripe,
      this.webhookSecret,
      this.logger,
    );
  }

  async createPaymentSession(
    params: PaymentSessionParams,
  ): Promise<Either<AppError, PaymentSessionResult>> {
    try {
      const reference = params.paymentGroupId ?? params.orderId ?? '';
      const fallbackKey = `${reference}-stripe-${params.amount}`;
      const lineItems = params.lineItems?.length
        ? params.lineItems
        : [{ name: 'FreeBay Order', amount: params.amount, quantity: 1 }];

      const session = await this.stripe.checkout.sessions.create(
        {
          mode: 'payment',
          line_items: lineItems.map((item) => ({
            price_data: {
              currency: params.currency || 'brl',
              product_data: { name: item.name },
              unit_amount: item.amount,
            },
            quantity: item.quantity,
          })),
          customer_email: params.customerEmail,
          success_url: params.successUrl,
          cancel_url: params.cancelUrl,
          metadata: {
            ...(params.orderId ? { orderId: params.orderId } : {}),
            ...(params.paymentGroupId ? { paymentGroupId: params.paymentGroupId } : {}),
           idempotencyKey: params.idempotencyKey || fallbackKey,
           customerName: params.customerName || '',
           customerTaxId: params.customerTaxId || '',
           },
           ...(params.transferGroup
             ? { payment_intent_data: { transfer_group: params.transferGroup } }
             : {}),
          expires_at: Math.floor(Date.now() / 1000) + CHECKOUT_EXPIRY_SECONDS,
        },
        { idempotencyKey: params.idempotencyKey || fallbackKey },
      );

      const expiresAt = new Date(Date.now() + CHECKOUT_EXPIRY_MILLISECONDS);

      return right({
        stripeSessionId: session.id,
        checkoutUrl: session.url || '',
        expiresAt,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Stripe payment session creation failed: ${message}`);
      return left(
        new PaymentProviderError(
          'Erro no provedor de pagamento',
          500,
        ),
      );
    }
  }

  async createPaymentIntent(
    params: PaymentIntentParams,
  ): Promise<Either<AppError, PaymentIntentResult>> {
    try {
      const reference = params.paymentGroupId ?? params.orderId ?? '';
      const fallbackKey = `${reference}-pi-${params.amount}`;

      const pi = await this.stripe.paymentIntents.create(
        {
          amount: params.amount,
          currency: params.currency || 'brl',
          receipt_email: params.receiptEmail,
          automatic_payment_methods: { enabled: true },
          metadata: {
            ...(params.orderId ? { orderId: params.orderId } : {}),
            ...(params.paymentGroupId ? { paymentGroupId: params.paymentGroupId } : {}),
            idempotencyKey: params.idempotencyKey || fallbackKey,
          },
          ...(params.transferGroup ? { transfer_group: params.transferGroup } : {}),
        },
        { idempotencyKey: params.idempotencyKey || fallbackKey },
      );

      return right({
        paymentIntentId: pi.id,
        clientSecret: pi.client_secret ?? '',
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`PaymentIntent creation failed: ${message}`);
      return left(
        new PaymentProviderError(
          'Erro no provedor de pagamento',
          500,
        ),
      );
    }
  }

  async cancelPendingPayment(payment: {
    stripeSessionId?: string;
    stripePaymentIntentId?: string;
    idempotencyKey: string;
  }): Promise<Either<AppError, void>> {
    try {
      if (payment.stripeSessionId) {
        await this.stripe.checkout.sessions.expire(
          payment.stripeSessionId,
          {},
          { idempotencyKey: payment.idempotencyKey },
        );
      } else if (payment.stripePaymentIntentId) {
        await this.stripe.paymentIntents.cancel(
          payment.stripePaymentIntentId,
          {},
          { idempotencyKey: payment.idempotencyKey },
        );
      } else {
        throw new Error('Stripe payment reference is missing');
      }
      return right(undefined);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Pending Stripe payment cancellation failed: ${message}`);
      return left(new PaymentProviderError('Erro ao cancelar pagamento pendente', 500));
    }
  }

  async refundPayment(payment: {
    orderId: string;
    amount: number;
    chargeId?: string;
    paymentIntentId?: string;
  }): Promise<Either<AppError, 'succeeded' | 'pending'>> {
    try {
      const refund = await this.stripe.refunds.create(
        {
          amount: payment.amount,
          ...(payment.chargeId
            ? { charge: payment.chargeId }
            : { payment_intent: payment.paymentIntentId }),
          reason: 'requested_by_customer',
        },
        { idempotencyKey: `order-cancel-${payment.orderId}` },
      );
      if (refund.status === 'succeeded') return right('succeeded');
      if (refund.status === 'pending') return right('pending');
      return left(new PaymentProviderError('O reembolso não foi aceito pelo provedor'));
    } catch (error) {
      this.logger.error(`Stripe refund failed for order ${payment.orderId}: ${error instanceof Error ? error.message : String(error)}`);
      return left(new PaymentProviderError('Erro ao solicitar reembolso'));
    }
  }


  async createConnectAccount(
    params: CreateConnectAccountParams,
  ): Promise<Either<AppError, ConnectAccountSnapshot>> {
    return this.connect.createAccount(params);
  }

  async refreshConnectAccount(
    stripeAccountId: string,
  ): Promise<Either<AppError, ConnectAccountSnapshot>> {
    return this.connect.refreshAccount(stripeAccountId);
  }

  async createOnboardingLink(
    stripeAccountId: string,
    refreshUrl: string,
    returnUrl: string,
  ): Promise<Either<AppError, string>> {
    return this.connect.createOnboardingLink(stripeAccountId, refreshUrl, returnUrl);
  }

  async createDashboardLink(stripeAccountId: string): Promise<Either<AppError, string>> {
    return this.connect.createDashboardLink(stripeAccountId);
  }

  async createTransfer(params: CreateTransferParams): Promise<Either<AppError, string>> {
    return this.connect.createTransfer(params);
  }

  async reverseTransfer(
    transferId: string,
    amount: number,
    orderId: string,
    transactionId: string,
    idempotencyKey: string,
  ): Promise<Either<AppError, string>> {
    return this.connect.reverseTransfer(
      transferId,
      amount,
      orderId,
      transactionId,
      idempotencyKey,
    );
  }

  async findTransfer(
    params: TransferReconciliationParams,
  ): Promise<Either<AppError, TransferReconciliationResult | null>> {
    return this.connect.findTransfer(params);
  }

  async findReversal(
    params: ReversalReconciliationParams,
  ): Promise<Either<AppError, string | null>> {
    return this.connect.findReversal(params);
  }

  verifyWebhook(payload: string, signature: string): boolean {
    return this.webhookVerifier.verify(payload, signature);
  }

  constructWebhookEvent(
    payload: string,
    signature: string,
  ): StripeWebhookEvent | null {
    return this.webhookVerifier.construct(payload, signature);
  }
}
