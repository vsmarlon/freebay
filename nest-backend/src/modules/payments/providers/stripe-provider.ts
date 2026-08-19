import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import {
  PaymentProvider,
  PaymentIntentParams,
  PaymentIntentResult,
  PaymentSessionParams,
  PaymentSessionResult,
} from '../domain/providers/payment-provider.interface';

@Injectable()
export class StripeProvider implements OnModuleInit, PaymentProvider {
  private readonly logger = new Logger(StripeProvider.name);
  private stripe: Stripe;
  private readonly webhookSecret: string;

  constructor(private readonly config: ConfigService) {
    const key = this.config.get('STRIPE_SECRET_KEY') || 'sk_test_placeholder';
    this.stripe = new Stripe(key);
    this.webhookSecret = this.config.get('STRIPE_WEBHOOK_SECRET') || '';
  }

  onModuleInit() {
    if (!this.webhookSecret) {
      throw new Error('STRIPE_WEBHOOK_SECRET is not configured');
    }
    if (!this.config.get('STRIPE_SECRET_KEY')) {
      throw new Error('STRIPE_SECRET_KEY is not configured');
    }
  }

  async createPaymentSession(
    params: PaymentSessionParams,
  ): Promise<Either<AppError, PaymentSessionResult>> {
    try {
      const session = await this.stripe.checkout.sessions.create(
        {
          mode: 'payment',
          line_items: [
            {
              price_data: {
                currency: params.currency || 'brl',
                product_data: {
                  name: params.customerName || 'FreeBay Order',
                },
                unit_amount: params.amount,
              },
              quantity: 1,
            },
          ],
          customer_email: params.customerEmail,
          success_url: params.successUrl,
          cancel_url: params.cancelUrl,
          metadata: {
            orderId: params.orderId,
            idempotencyKey: params.idempotencyKey || `${params.orderId}-stripe-${params.amount}`,
            customerName: params.customerName || '',
            customerTaxId: params.customerTaxId || '',
          },
          expires_at: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
        },
        {
          idempotencyKey:
            params.idempotencyKey || `${params.orderId}-stripe-${params.amount}`,
        },
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
        new AppError(
          'PAYMENT_PROVIDER_ERROR',
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
      const pi = await this.stripe.paymentIntents.create(
        {
          amount: params.amount,
          currency: params.currency || 'brl',
          receipt_email: params.receiptEmail,
          automatic_payment_methods: { enabled: true },
          metadata: {
            orderId: params.orderId,
            idempotencyKey:
              params.idempotencyKey || `${params.orderId}-pi-${params.amount}`,
          },
        },
        {
          idempotencyKey:
            params.idempotencyKey || `${params.orderId}-pi-${params.amount}`,
        },
      );

      return right({
        paymentIntentId: pi.id,
        clientSecret: pi.client_secret ?? '',
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`PaymentIntent creation failed: ${message}`);
      return left(
        new AppError(
          'PAYMENT_PROVIDER_ERROR',
          `Stripe error: ${message}`,
          500,
        ),
      );
    }
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
