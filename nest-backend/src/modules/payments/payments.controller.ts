import {
  Controller,
  Post,
  Param,
  HttpStatus,
  Headers,
  Logger,
  Req,
  ParseUUIDPipe,
} from '@nestjs/common';
import Stripe from 'stripe';
import { ApiTags } from '@nestjs/swagger';
import { PostAuth, StripeWebhook, CurrentUserId } from '@/shared/decorators';
import { CreatePaymentSessionUseCase } from './usecases/create-payment-session.usecase';
import { CreatePaymentIntentUseCase } from './usecases/create-payment-intent.usecase';
import { CreateCryptoPaymentUseCase } from './usecases/create-crypto-payment.usecase';
import { ProcessWebhookUseCase } from './usecases/process-webhook.usecase';
import { CreatePaymentSessionOutput, CreatePaymentIntentOutput, CreateCryptoPaymentOutput } from './dtos/payment.dto';
import { right } from '@/shared/core/either';

interface WebhookRequest {
  stripeEvent?: Stripe.Event;
}

const WHITELIST_EVENTS = [
  'checkout.session.completed',
  'checkout.session.async_payment_succeeded',
  'checkout.session.async_payment_failed',
  'checkout.session.expired',
  'payment_intent.succeeded',
  'payment_intent.canceled',
  'payment_intent.payment_failed',
];

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(
    private readonly createPaymentSessionUseCase: CreatePaymentSessionUseCase,
    private readonly createPaymentIntentUseCase: CreatePaymentIntentUseCase,
    private readonly createCryptoPaymentUseCase: CreateCryptoPaymentUseCase,
    private readonly processWebhookUseCase: ProcessWebhookUseCase,
  ) {}

  @PostAuth('checkout/:orderId', {
    summary: 'Create Stripe Checkout payment session',
    description: 'Creates a Stripe Checkout Session for an order (rate limited: 5/min)',
    responseStatus: 201,
    responseType: CreatePaymentSessionOutput,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 429, description: 'Too many requests' }],
    throttle: { limit: 5, ttl: 60000 },
    httpCode: HttpStatus.CREATED,
  })
  async createPaymentSession(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUserId() userId: string,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    return this.createPaymentSessionUseCase.execute({ orderId, userId, idempotencyKey });
  }

  @PostAuth('payment-intent/:orderId', {
    summary: 'Create Stripe PaymentIntent for PaymentSheet',
    description: 'Creates a Stripe PaymentIntent for an order (mobile PaymentSheet; rate limited: 5/min)',
    responseStatus: 201,
    responseType: CreatePaymentIntentOutput,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 429, description: 'Too many requests' }],
    throttle: { limit: 5, ttl: 60000 },
    httpCode: HttpStatus.CREATED,
  })
  async createPaymentIntent(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUserId() userId: string,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    return this.createPaymentIntentUseCase.execute({ orderId, userId, idempotencyKey });
  }

  @PostAuth('crypto/:orderId', {
    summary: 'Create Monero Ephemeral Payment Address',
    description: 'Generates a disposable untrackable Monero (XMR) subaddress and QR URI for private escrow (rate limited: 5/min)',
    responseStatus: 201,
    responseType: CreateCryptoPaymentOutput,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 429, description: 'Too many requests' }],
    throttle: { limit: 5, ttl: 60000 },
    httpCode: HttpStatus.CREATED,
  })
  async createCryptoPayment(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.createCryptoPaymentUseCase.execute({ orderId, userId, currency: 'XMR' });
  }

  @Post('webhook')
  @StripeWebhook
  async handleWebhook(@Req() request: WebhookRequest) {
    const event = request.stripeEvent;
    if (!event) {
      this.logger.error('Webhook guard did not attach stripeEvent to request');
      return right({ processed: false });
    }

    if (!WHITELIST_EVENTS.includes(event.type)) {
      return right({ processed: false });
    }

    let orderId: string | undefined;
    let providerObjectId: string | undefined;
    let amountTotal: number | undefined;
    let currency: string | undefined;
    let paymentStatus: string | undefined;

    if (event.type.startsWith('checkout.session.')) {
      const session = event.data.object as Stripe.Checkout.Session;
      orderId = session.metadata?.orderId ?? undefined;
      providerObjectId = session.id;
      amountTotal = session.amount_total ?? undefined;
      currency = session.currency ?? undefined;
      paymentStatus = session.payment_status;
    } else {
      const intent = event.data.object as Stripe.PaymentIntent;
      orderId = intent.metadata?.orderId ?? undefined;
      providerObjectId = intent.id;
      amountTotal = intent.amount ?? undefined;
      currency = intent.currency ?? undefined;
      paymentStatus = intent.status;
    }

    return this.processWebhookUseCase.execute({
      event: event.type,
      data: { orderId, providerObjectId, amountTotal, currency, paymentStatus },
    });
  }
}
