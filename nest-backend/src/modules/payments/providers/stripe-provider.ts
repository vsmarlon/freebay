import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
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
  ConnectStatus,
  CreateConnectAccountParams,
  CreateTransferParams,
  TransferReconciliationParams,
  TransferReconciliationResult,
  ReversalReconciliationParams,
} from '../types/connect.types';

export type StripeWebhookEvent = Stripe.Event | Stripe.V2.Core.EventNotification;
export type VerifiedV2AccountWebhookEvent = Extract<
  Stripe.V2.Core.EventNotification,
  { related_object: { id: string; type: string } }
>;

@Injectable()
export class StripeProvider {
  private static readonly API_VERSION = '2026-07-29.dahlia';
  private readonly logger = new Logger(StripeProvider.name);
  private readonly stripe: Stripe;
  private readonly webhookSecret: string;

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
          expires_at: Math.floor(Date.now() / 1000) + 3600,
        },
        { idempotencyKey: params.idempotencyKey || fallbackKey },
      );

      const expiresAt = new Date(Date.now() + 3600 * 1000);

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


  async createConnectAccount(
    params: CreateConnectAccountParams,
  ): Promise<Either<AppError, ConnectAccountSnapshot>> {
    try {
      const account = await this.stripe.v2.core.accounts.create({
        contact_email: params.email,
        display_name: params.displayName,
        dashboard: 'express',
        identity: { country: params.country },
        defaults: {
          currency: params.currency,
          responsibilities: {
            fees_collector: 'application',
            losses_collector: 'application',
          },
        },
        configuration: {
          recipient: {
            capabilities: { stripe_balance: { stripe_transfers: { requested: true } } },
          },
        },
        include: ['configuration.recipient', 'identity', 'requirements', 'future_requirements'],
      });

      return right(this.toSnapshot(account, params.country, params.currency));
    } catch (error) {
      return left(this.connectError('Connect account creation', error));
    }
  }

  async refreshConnectAccount(
    stripeAccountId: string,
  ): Promise<Either<AppError, ConnectAccountSnapshot>> {
    try {
      const account = await this.stripe.v2.core.accounts.retrieve(stripeAccountId, {
          include: ['configuration.recipient', 'identity', 'requirements', 'future_requirements'],
      });
      return right(this.toSnapshot(account, '', ''));
    } catch (error) {
      return left(this.connectError('Connect account refresh', error));
    }
  }

  async createOnboardingLink(
    stripeAccountId: string,
    refreshUrl: string,
    returnUrl: string,
  ): Promise<Either<AppError, string>> {
    try {
      const link = await this.stripe.v2.core.accountLinks.create({
        account: stripeAccountId,
        use_case: {
          type: 'account_onboarding',
          account_onboarding: {
            configurations: ['recipient'],
            refresh_url: refreshUrl,
            return_url: returnUrl,
          },
        },
      });
      return right(link.url);
    } catch (error) {
      return left(this.connectError('Connect onboarding link', error));
    }
  }

  async createDashboardLink(stripeAccountId: string): Promise<Either<AppError, string>> {
    try {
      const link = await this.stripe.accounts.createLoginLink(stripeAccountId);
      return right(link.url);
    } catch (error) {
      return left(this.connectError('Connect dashboard link', error));
    }
  }

  async createTransfer(params: CreateTransferParams): Promise<Either<AppError, string>> {
    try {
      const transfer = await this.stripe.transfers.create(
        {
          amount: params.amount,
          currency: params.currency,
          destination: params.destination,
          source_transaction: params.sourceTransaction,
           transfer_group: params.transferGroup,
           metadata: {
             orderId: params.orderId,
             transactionId: params.transactionId,
             ...(params.paymentGroupId ? { paymentGroupId: params.paymentGroupId } : {}),
             idempotencyKey: params.idempotencyKey,
           },
        },
        { idempotencyKey: params.idempotencyKey },
      );
      return right(transfer.id);
    } catch (error) {
      return left(this.connectError('Transfer creation', error));
    }
  }

  async reverseTransfer(
    transferId: string,
    amount: number,
    orderId: string,
    transactionId: string,
    idempotencyKey: string,
  ): Promise<Either<AppError, string>> {
    try {
      const reversal = await this.stripe.transfers.createReversal(
        transferId,
         { amount, metadata: { orderId, transactionId, idempotencyKey } },
         { idempotencyKey },
      );
      return right(reversal.id);
    } catch (error) {
      return left(this.connectError('Transfer reversal', error));
    }
  }

  async findTransfer(
    params: TransferReconciliationParams,
  ): Promise<Either<AppError, TransferReconciliationResult | null>> {
    try {
      if (params.transferId) {
        const transfer = await this.stripe.transfers.retrieve(params.transferId);
        return right(this.matchesTransfer(transfer, params) ? { providerId: transfer.id } : null);
      }

      const transfers = await this.stripe.transfers.list({ transfer_group: params.transferGroup, limit: 100 });
      const match = transfers.data.find((transfer) => this.matchesTransfer(transfer, params));
      return right(match ? { providerId: match.id } : null);
    } catch (error) {
      return left(this.connectError('Transfer reconciliation', error));
    }
  }

  private matchesTransfer(
    transfer: Stripe.Transfer,
    params: TransferReconciliationParams,
  ): boolean {
    return transfer.destination === params.destination &&
      transfer.transfer_group === params.transferGroup &&
      transfer.metadata.orderId === params.orderId &&
      transfer.metadata.transactionId === params.transactionId &&
      transfer.metadata.idempotencyKey === params.idempotencyKey &&
      (!params.paymentGroupId || transfer.metadata.paymentGroupId === params.paymentGroupId);
  }

  async findReversal(
    params: ReversalReconciliationParams,
  ): Promise<Either<AppError, string | null>> {
    try {
      if (!params.reversalId) return right(null);
      const reversal = await this.stripe.transfers.retrieveReversal(params.transferId, params.reversalId);
      const metadata = reversal.metadata ?? {};
      return right(
        metadata.orderId === params.orderId &&
        metadata.transactionId === params.transactionId &&
        metadata.idempotencyKey === params.idempotencyKey
          ? reversal.id
          : null,
      );
    } catch (error) {
      return left(this.connectError('Reversal reconciliation', error));
    }
  }

  private toSnapshot(
    account: Stripe.V2.Core.Account,
    fallbackCountry: string,
    fallbackCurrency: string,
  ): ConnectAccountSnapshot {
    const balance = account.configuration?.recipient?.capabilities?.stripe_balance;
    const requirements = account.requirements?.entries ?? [];
    const transferStatus = balance?.stripe_transfers?.status;
    const hasDueRequirements = requirements.some(
      (entry) =>
        entry.minimum_deadline.status === 'currently_due' ||
        entry.minimum_deadline.status === 'past_due',
    );
    const hasRecipient =
      account.configuration?.recipient !== undefined &&
      account.applied_configurations.includes('recipient');
    let status: ConnectStatus = 'onboarding-required';
    if (account.closed || transferStatus === 'restricted' || transferStatus === 'unsupported') {
      status = 'restricted';
    } else if (!hasRecipient) {
      status = 'onboarding-required';
    } else if (transferStatus === 'active') {
      status = 'transfer-ready';
    } else if (transferStatus === 'pending' && hasDueRequirements) {
      status = 'requirements-due';
    }

    return {
      stripeAccountId: account.id,
      country: account.identity?.country ?? fallbackCountry,
      defaultCurrency: account.defaults?.currency ?? fallbackCurrency,
      status,
      transfersEnabled: balance?.stripe_transfers?.status === 'active',
      payoutsEnabled: balance?.payouts?.status === 'active',
      detailsSubmitted: hasRecipient,
      requirementsDue: requirements
        .filter(
          (entry) =>
            entry.minimum_deadline.status === 'currently_due' ||
            entry.minimum_deadline.status === 'past_due',
        )
        .map((entry) => entry.description),
    };
  }

  private connectError(operation: string, error: unknown): AppError {
    const message = error instanceof Error ? error.message : 'Unknown error';
    this.logger.error(`${operation} failed: ${message}`);
    const statusCode = error instanceof Stripe.errors.StripeError
      ? error.statusCode ?? 500
      : 500;
    return new PaymentProviderError('Erro na integração de pagamentos', statusCode);
  }

  verifyWebhook(payload: string, signature: string): boolean {
    if (!this.webhookSecret) {
      return false;
    }
    if (!signature) {
      return false;
    }
    const event = this.constructWebhookEvent(payload, signature);
    return event !== null;
  }

  constructWebhookEvent(
    payload: string,
    signature: string,
  ): StripeWebhookEvent | null {
    if (!this.webhookSecret) {
      return null;
    }
    try {
      return this.stripe.webhooks.constructEvent(
        payload,
        signature,
        this.webhookSecret,
      );
    } catch (v1Error) {
      try {
        return this.stripe.parseEventNotification(payload, signature, this.webhookSecret) ?? null;
      } catch (v2Error) {
        this.logger.warn(
          `Webhook signature verification failed: ${
            v2Error instanceof Error
              ? v2Error.message
              : v1Error instanceof Error
                ? v1Error.message
                : 'Unknown'
          }`,
        );
        return null;
      }
    }
  }
}
