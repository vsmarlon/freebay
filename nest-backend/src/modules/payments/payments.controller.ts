import {
  Controller,
  Post,
  Param,
  HttpStatus,
  Headers,
  Logger,
  Req,
} from '@nestjs/common';
import Stripe from 'stripe';
import { ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { Authenticated, StripeWebhook } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { CreatePaymentSessionUseCase } from './usecases/create-payment-session.usecase';
import { CreatePaymentIntentUseCase } from './usecases/create-payment-intent.usecase';
import { ProcessWebhookUseCase } from './usecases/process-webhook.usecase';
import { CreatePaymentSessionOutput, CreatePaymentIntentOutput } from './dtos/payment.dto';

interface WebhookRequest {
  stripeEvent?: Stripe.Event;
}

const WHITELIST_EVENTS = [
  'checkout.session.completed',
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
    private readonly processWebhookUseCase: ProcessWebhookUseCase,
  ) {}

  @Post('checkout/:orderId')
  @Authenticated({
    summary: 'Create Stripe Checkout payment session',
    description: 'Creates a Stripe Checkout Session for an order (rate limited: 5/min)',
    responseStatus: 201,
    responseType: CreatePaymentSessionOutput,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 429, description: 'Too many requests' }],
    throttle: { limit: 5, ttl: 60000 },
    httpCode: HttpStatus.CREATED,
    guards: [JwtAuthGuard],
  })
  async createPaymentSession(
    @Param('orderId') orderId: string,
    @CurrentUser() user: AuthUser,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    this.logger.log(`Creating payment session for order ${orderId} by user ${user.userId}`);
    const result = await this.createPaymentSessionUseCase.execute({ orderId, userId: user.userId, idempotencyKey });
    if (result.isLeft()) {
      this.logger.error(`Payment session creation failed for order ${orderId}: ${result.value.message}`);
    } else {
      this.logger.log(`Payment session created: ${result.value.stripeSessionId} for order ${orderId}`);
    }
    return result;
  }

  @Post('payment-intent/:orderId')
  @Authenticated({
    summary: 'Create Stripe PaymentIntent for PaymentSheet',
    description: 'Creates a Stripe PaymentIntent for an order (mobile PaymentSheet; rate limited: 5/min)',
    responseStatus: 201,
    responseType: CreatePaymentIntentOutput,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 429, description: 'Too many requests' }],
    throttle: { limit: 5, ttl: 60000 },
    httpCode: HttpStatus.CREATED,
    guards: [JwtAuthGuard],
  })
  async createPaymentIntent(
    @Param('orderId') orderId: string,
    @CurrentUser() user: AuthUser,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    this.logger.log(`Creating PaymentIntent for order ${orderId} by user ${user.userId}`);
    const result = await this.createPaymentIntentUseCase.execute({ orderId, userId: user.userId, idempotencyKey });
    if (result.isLeft()) {
      this.logger.error(`PaymentIntent creation failed for order ${orderId}: ${result.value.message}`);
    } else {
      this.logger.log(`PaymentIntent created for order ${orderId}`);
    }
    return result;
  }

  @Post('webhook')
  @StripeWebhook
  async handleWebhook(@Req() request: WebhookRequest) {
    const event = request.stripeEvent;
    if (!event) {
      this.logger.error('Webhook guard did not attach stripeEvent to request');
      return { processed: false };
    }

    if (!WHITELIST_EVENTS.includes(event.type)) {
      this.logger.log(`Ignoring unhandled webhook event: ${event.type}`);
      return { processed: false };
    }

    const object = event.data.object as { metadata?: { orderId?: string } };
    const orderId = object.metadata?.orderId;
    this.logger.log(`Received Stripe webhook: ${event.type} for order ${orderId}`);

    const result = await this.processWebhookUseCase.execute({ event: event.type, data: { orderId } });
    if (result.isLeft()) {
      this.logger.error(`Webhook processing failed for ${event.type}: ${result.value.message}`);
    } else {
      this.logger.log(`Webhook processed: ${event.type}, processed=${result.value.processed}`);
    }
    return result;
  }
}
