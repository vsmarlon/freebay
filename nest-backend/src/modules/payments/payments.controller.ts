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
import { GetAuth, PostAuth, StripeWebhook, CurrentUserId } from '@/shared/decorators';
import { CreatePaymentSessionUseCase } from './usecases/create-payment-session.usecase';
import { CreatePaymentIntentUseCase } from './usecases/create-payment-intent.usecase';
import { ProcessWebhookUseCase } from './usecases/process-webhook.usecase';
import { ProcessGroupWebhookUseCase } from './usecases/process-group-webhook.usecase';
import { ProcessRefundUseCase } from './usecases/process-refund.usecase';
import { StartConnectOnboardingUseCase } from './usecases/start-connect-onboarding.usecase';
import { GetConnectStatusUseCase } from './usecases/get-connect-status.usecase';
import { GetConnectDashboardLinkUseCase } from './usecases/get-connect-dashboard-link.usecase';
import { SyncConnectAccountUseCase } from './usecases/sync-connect-account.usecase';
import {
  ConnectStatusOutput,
  ConnectOnboardingOutput,
  ConnectDashboardOutput,
} from './dtos/connect.dto';
import { CreatePaymentSessionOutput, CreatePaymentIntentOutput } from './dtos/payment.dto';
import { right } from '@/shared/core/either';
import { setContextUserId } from '@/shared/observability/request-context';

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
  'account.updated',
  'charge.refunded',
  'charge.dispute.created',
  'charge.dispute.closed',
];

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(
    private readonly createPaymentSessionUseCase: CreatePaymentSessionUseCase,
    private readonly createPaymentIntentUseCase: CreatePaymentIntentUseCase,
    private readonly processWebhookUseCase: ProcessWebhookUseCase,
    private readonly processGroupWebhookUseCase: ProcessGroupWebhookUseCase,
    private readonly processRefundUseCase: ProcessRefundUseCase,
    private readonly startConnectOnboardingUseCase: StartConnectOnboardingUseCase,
    private readonly getConnectStatusUseCase: GetConnectStatusUseCase,
    private readonly getConnectDashboardLinkUseCase: GetConnectDashboardLinkUseCase,
    private readonly syncConnectAccountUseCase: SyncConnectAccountUseCase,
  ) {}

  @PostAuth('connect/onboarding', {
    summary: 'Start or resume Stripe Connect onboarding',
    description: 'Creates the connected account if needed and returns a hosted onboarding link',
    responseStatus: 201,
    responseType: ConnectOnboardingOutput,
    httpCode: HttpStatus.CREATED,
  })
  async startConnectOnboarding(@CurrentUserId() userId: string) {
    return this.startConnectOnboardingUseCase.execute(userId);
  }

  @GetAuth('connect/status', {
    summary: 'Get Stripe Connect account status',
    description: 'Returns onboarding and capability state for the current seller',
    responseType: ConnectStatusOutput,
  })
  async getConnectStatus(@CurrentUserId() userId: string) {
    return this.getConnectStatusUseCase.execute(userId);
  }

  @PostAuth('connect/dashboard', {
    summary: 'Open the Stripe Express dashboard',
    description: 'Returns a single-use login link to the seller Express dashboard',
    responseStatus: 201,
    responseType: ConnectDashboardOutput,
    httpCode: HttpStatus.CREATED,
  })
  async getConnectDashboardLink(@CurrentUserId() userId: string) {
    return this.getConnectDashboardLinkUseCase.execute(userId);
  }

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

  @Post('webhook')
  @StripeWebhook
  async handleWebhook(@Req() request: WebhookRequest) {
    const event = request.stripeEvent;
    if (!event) {
      this.logger.error('Webhook guard did not attach stripeEvent to request');
      return right(undefined);
    }

    setContextUserId(`stripe-event:${event.id}`);

    if (!WHITELIST_EVENTS.includes(event.type)) {
      this.logger.log(`Ignoring non-whitelisted Stripe event ${event.type} (${event.id})`);
      return right(undefined);
    }

    if (event.type === 'account.updated' || event.type.startsWith('v2.core.account')) {
      const accountId =
        event.account ?? (event.data.object as { id?: string }).id ?? undefined;
      if (!accountId) return right(undefined);
      return this.syncConnectAccountUseCase.execute(accountId);
    }

    if (event.type.startsWith('charge.')) {
      const charge = event.data.object as Stripe.Charge | Stripe.Dispute;
      const chargeId =
        'charge' in charge && typeof charge.charge === 'string' ? charge.charge : charge.id;
      if (event.type === 'charge.refunded') {
        return this.processRefundUseCase.execute(chargeId);
      }
      this.logger.warn(`Dispute event ${event.type} received for charge ${chargeId}`);
      return right(undefined);
    }

    let orderId: string | undefined;
    let paymentGroupId: string | undefined;
    let providerObjectId: string | undefined;
    let amountTotal: number | undefined;
    let currency: string | undefined;
    let paymentStatus: string | undefined;
    let chargeId: string | undefined;

    if (event.type.startsWith('checkout.session.')) {
      const session = event.data.object as Stripe.Checkout.Session;
      orderId = session.metadata?.orderId ?? undefined;
      paymentGroupId = session.metadata?.paymentGroupId ?? undefined;
      providerObjectId = session.id;
      amountTotal = session.amount_total ?? undefined;
      currency = session.currency ?? undefined;
      paymentStatus = session.payment_status;
      chargeId =
        typeof session.payment_intent === 'string'
          ? undefined
          : ((session.payment_intent?.latest_charge as string | undefined) ?? undefined);
    } else {
      const intent = event.data.object as Stripe.PaymentIntent;
      orderId = intent.metadata?.orderId ?? undefined;
      paymentGroupId = intent.metadata?.paymentGroupId ?? undefined;
      providerObjectId = intent.id;
      amountTotal = intent.amount ?? undefined;
      currency = intent.currency ?? undefined;
      paymentStatus = intent.status;
      chargeId = typeof intent.latest_charge === 'string' ? intent.latest_charge : (intent.latest_charge?.id ?? undefined);
    }

    const data = {
      orderId,
      paymentGroupId,
      providerObjectId,
      amountTotal,
      currency,
      paymentStatus,
      chargeId,
    };

    if (paymentGroupId) {
      return this.processGroupWebhookUseCase.execute({ event: event.type, data });
    }

    return this.processWebhookUseCase.execute({ event: event.type, data });
  }
}
