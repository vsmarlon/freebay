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
  PaymentSessionSnapshot,
  ChargeRefundSnapshot,
  RefundSnapshot,
  RefundStatus,
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

/** Stripe refund status → domain value set; anything unrecognized falls back to UNKNOWN. */
const KNOWN_REFUND_STATUSES = new Map<string, RefundStatus>([
  [RefundStatus.PENDING, RefundStatus.PENDING],
  [RefundStatus.REQUIRES_ACTION, RefundStatus.REQUIRES_ACTION],
  [RefundStatus.SUCCEEDED, RefundStatus.SUCCEEDED],
  [RefundStatus.FAILED, RefundStatus.FAILED],
  [RefundStatus.CANCELED, RefundStatus.CANCELED],
]);

function mapRefund(refund: Stripe.Refund): RefundSnapshot {
  const knownStatus = KNOWN_REFUND_STATUSES.get(refund.status ?? '') ?? RefundStatus.UNKNOWN;
  return {
    id: refund.id,
    chargeId: typeof refund.charge === 'string' ? refund.charge : refund.charge?.id ?? null,
    amount: refund.amount,
    status: knownStatus,
    orderId: refund.metadata?.orderId || null,
    operationId: refund.metadata?.operationId || null,
  };
}

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
            ...(params.buyerId ? { buyerId: params.buyerId } : {}),
            idempotencyKey: params.idempotencyKey || fallbackKey,
          },
           ...(params.transferGroup
             ? { payment_intent_data: { transfer_group: params.transferGroup } }
             : {}),
          expires_at: params.expiresAt
            ? Math.floor(params.expiresAt.getTime() / 1000)
            : Math.floor(Date.now() / 1000) + CHECKOUT_EXPIRY_SECONDS,
        },
        { idempotencyKey: params.idempotencyKey || fallbackKey },
      );

      const expiresAt = session.expires_at
        ? new Date(session.expires_at * 1000)
        : new Date(Date.now() + CHECKOUT_EXPIRY_MILLISECONDS);

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

  async retrievePaymentSession(sessionId: string): Promise<Either<AppError, PaymentSessionSnapshot>> {
    try {
      const session = await this.stripe.checkout.sessions.retrieve(sessionId);
      return right({
        stripeSessionId: session.id,
        checkoutUrl: session.url,
        status: session.status,
        mode: session.mode,
        paymentStatus: session.payment_status,
        amountTotal: session.amount_total,
        currency: session.currency,
        orderId: session.metadata?.orderId ?? null,
        paymentGroupId: session.metadata?.paymentGroupId ?? null,
        buyerId: session.metadata?.buyerId ?? null,
        idempotencyKey: session.metadata?.idempotencyKey ?? null,
        expiresAt: session.expires_at ? new Date(session.expires_at * 1000) : null,
      });
    } catch (error) {
      this.logger.error(`Checkout Session reconciliation failed for ${sessionId}: ${error instanceof Error ? error.message : String(error)}`);
      return left(new PaymentProviderError('Não foi possível reconciliar a sessão de pagamento'));
    }
  }

  async cancelPendingPayment(payment: {
    stripeSessionId?: string;
    stripePaymentIntentId?: string;
    idempotencyKey: string;
  }): Promise<Either<AppError, void>> {
    try {
      if (payment.stripeSessionId) {
        let session = await this.stripe.checkout.sessions.retrieve(payment.stripeSessionId);
        if (session.status === 'open') {
          session = await this.stripe.checkout.sessions.expire(
            payment.stripeSessionId,
            {},
            { idempotencyKey: payment.idempotencyKey },
          );
        }
        if (session.status !== 'expired') {
          return left(new PaymentProviderError('Pagamento ainda não está terminal; reconciliação necessária'));
        }
      } else if (payment.stripePaymentIntentId) {
        let intent = await this.stripe.paymentIntents.retrieve(payment.stripePaymentIntentId);
        if (intent.status === 'canceled') return right(undefined);
        if (!['requires_payment_method', 'requires_confirmation', 'requires_action', 'requires_capture'].includes(intent.status)) {
          return left(new PaymentProviderError('Pagamento ainda não está terminal; reconciliação necessária'));
        }
        intent = await this.stripe.paymentIntents.cancel(
          payment.stripePaymentIntentId,
          {},
          { idempotencyKey: payment.idempotencyKey },
        );
        if (intent.status !== 'canceled') {
          return left(new PaymentProviderError('Cancelamento do pagamento não foi confirmado'));
        }
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
    operationId: string;
    idempotencyKey: string;
    knownProviderId: string | null;
    allowCreate: boolean;
  }): Promise<Either<AppError, RefundSnapshot>> {
    try {
      if (!payment.chargeId) {
        return left(new PaymentProviderError('Referência de pagamento ausente para reembolso'));
      }
      const listed = await this.stripe.refunds.list({ charge: payment.chargeId, limit: 100 });
      if (listed.has_more) {
        return left(new PaymentProviderError('A lista de reembolsos exige reconciliação manual'));
      }
      const operationMatches = listed.data
        .map(mapRefund)
        .filter((refund) => refund.operationId === payment.operationId);
      if (operationMatches.length > 1) {
        return left(new PaymentProviderError('Mais de um reembolso corresponde à operação; reconciliação manual necessária'));
      }
      const existing = operationMatches[0];
      if (existing) {
        if (
          existing.orderId !== payment.orderId ||
          existing.chargeId !== payment.chargeId ||
          existing.amount !== payment.amount ||
          (payment.knownProviderId !== null && existing.id !== payment.knownProviderId)
        ) {
          return left(new PaymentProviderError('O reembolso canônico não corresponde à operação persistida'));
        }
        return right(existing);
      }
      if (!payment.allowCreate || payment.knownProviderId !== null) {
        return left(new PaymentProviderError('A operação não tem reembolso canônico; reconciliação manual necessária'));
      }
      const refund = await this.stripe.refunds.create(
        {
          amount: payment.amount,
          charge: payment.chargeId,
          reason: 'requested_by_customer',
          metadata: { orderId: payment.orderId, operationId: payment.operationId },
        },
        { idempotencyKey: payment.idempotencyKey },
      );
      return right(mapRefund(refund));
    } catch (error) {
      this.logger.error(`Stripe refund failed for order ${payment.orderId}: ${error instanceof Error ? error.message : String(error)}`);
      return left(new PaymentProviderError('Erro ao solicitar reembolso'));
    }
  }

  async retrieveRefund(refundId: string): Promise<Either<AppError, RefundSnapshot>> {
    try {
      return right(mapRefund(await this.stripe.refunds.retrieve(refundId)));
    } catch {
      return left(new PaymentProviderError('Não foi possível reconciliar o reembolso'));
    }
  }

  async retrieveChargeRefunds(chargeId: string): Promise<Either<AppError, ChargeRefundSnapshot>> {
    try {
      const [charge, refunds] = await Promise.all([
        this.stripe.charges.retrieve(chargeId),
        this.stripe.refunds.list({ charge: chargeId, limit: 100 }),
      ]);
      if (refunds.has_more) {
        return left(new PaymentProviderError('A lista de reembolsos exige reconciliação manual'));
      }
      const snapshots = refunds.data.map(mapRefund);
      if (new Set(snapshots.map((refund) => refund.id)).size !== snapshots.length) {
        return left(new PaymentProviderError('A lista de reembolsos está incompleta; reconciliação manual necessária'));
      }
      return right({
        id: charge.id,
        amount: charge.amount,
        amountRefunded: charge.amount_refunded,
        refunds: snapshots,
      });
    } catch {
      return left(new PaymentProviderError('Não foi possível reconciliar os reembolsos da cobrança'));
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
