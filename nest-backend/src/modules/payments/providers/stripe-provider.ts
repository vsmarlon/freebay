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
  CreateConnectAccountParams,
  CreateTransferParams,
} from '../types/connect.types';

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
          `Stripe error: ${message}`,
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
          `Stripe error: ${message}`,
          500,
        ),
      );
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
        include: ['configuration.recipient', 'identity', 'requirements'],
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
        include: ['configuration.recipient', 'identity', 'requirements'],
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
          metadata: { orderId: params.orderId },
        },
        { idempotencyKey: `transfer-${params.orderId}` },
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
  ): Promise<Either<AppError, string>> {
    try {
      const reversal = await this.stripe.transfers.createReversal(
        transferId,
        { amount, metadata: { orderId } },
        { idempotencyKey: `reversal-${orderId}` },
      );
      return right(reversal.id);
    } catch (error) {
      return left(this.connectError('Transfer reversal', error));
    }
  }

  private toSnapshot(
    account: Stripe.V2.Core.Account,
    fallbackCountry: string,
    fallbackCurrency: string,
  ): ConnectAccountSnapshot {
    const balance = account.configuration?.recipient?.capabilities?.stripe_balance;
    const requirements = account.requirements?.entries ?? [];

    return {
      stripeAccountId: account.id,
      country: account.identity?.country ?? fallbackCountry,
      defaultCurrency: account.defaults?.currency ?? fallbackCurrency,
      transfersEnabled: balance?.stripe_transfers?.status === 'active',
      payoutsEnabled: balance?.payouts?.status === 'active',
      detailsSubmitted: requirements.length === 0,
      requirementsDue: requirements.map((entry) => entry.description),
    };
  }

  private connectError(operation: string, error: unknown): AppError {
    const message = error instanceof Error ? error.message : 'Unknown error';
    this.logger.error(`${operation} failed: ${message}`);
    return new PaymentProviderError(`Stripe error: ${message}`, 500);
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
  ): Stripe.Event | null {
    if (!this.webhookSecret) {
      return null;
    }
    try {
      return this.stripe.webhooks.constructEvent(
        payload,
        signature,
        this.webhookSecret,
      );
    } catch (error) {
      this.logger.warn(
        `Webhook signature verification failed: ${error instanceof Error ? error.message : 'Unknown'}`,
      );
      return null;
    }
  }
}
