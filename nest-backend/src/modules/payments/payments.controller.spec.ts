import { Test } from '@nestjs/testing';
import Stripe from 'stripe';
import { right } from '@/shared/core/either';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { WebhookDedupeInterceptor } from '@/shared/interceptors/webhook-dedupe.interceptor';
import { PaymentsController } from './payments.controller';
import { CreatePaymentSessionUseCase } from './usecases/create-payment-session.usecase';
import { CreatePaymentIntentUseCase } from './usecases/create-payment-intent.usecase';
import { ProcessWebhookUseCase } from './usecases/process-webhook.usecase';
import { ProcessGroupWebhookUseCase } from './usecases/process-group-webhook.usecase';
import { ProcessRefundUseCase } from './usecases/process-refund.usecase';
import { StartConnectOnboardingUseCase } from './usecases/start-connect-onboarding.usecase';
import { GetConnectStatusUseCase } from './usecases/get-connect-status.usecase';
import { GetConnectDashboardLinkUseCase } from './usecases/get-connect-dashboard-link.usecase';
import { SyncConnectAccountUseCase } from './usecases/sync-connect-account.usecase';
import { RecoverDisputeTransferUseCase } from './usecases/recover-dispute-transfer.usecase';

type V2AccountEventType =
  | 'v2.core.account.updated'
  | 'v2.core.account.closed'
  | 'v2.core.account[configuration.recipient].updated'
  | 'v2.core.account[configuration.recipient].capability_status_updated'
  | 'v2.core.account[requirements].updated'
  | 'v2.core.account[future_requirements].updated';

function event(type: V2AccountEventType, relatedType = 'v2.core.account'): Stripe.V2.Core.EventNotification {
  return {
    id: `evt_${type}`,
    object: 'v2.core.event',
    created: new Date().toISOString(),
    livemode: false,
    type,
    related_object: { id: 'acct_1', type: relatedType, url: '' },
    fetchRelatedObject: async () => {
      throw new Error('not used');
    },
    fetchEvent: async () => {
      throw new Error('not used');
    },
  };
}

describe('PaymentsController Connect webhooks', () => {
  it('routes the legacy v1 account.updated event by its account id', async () => {
    const sync = { execute: jest.fn().mockResolvedValue(right({ processed: true })) };
    const module = await Test.createTestingModule({
      controllers: [PaymentsController],
      providers: [
        { provide: CreatePaymentSessionUseCase, useValue: { execute: jest.fn() } },
        { provide: CreatePaymentIntentUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessGroupWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessRefundUseCase, useValue: { execute: jest.fn() } },
        { provide: StartConnectOnboardingUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectStatusUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectDashboardLinkUseCase, useValue: { execute: jest.fn() } },
        { provide: SyncConnectAccountUseCase, useValue: sync },
        { provide: RecoverDisputeTransferUseCase, useValue: { execute: jest.fn() } },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(WebhookGuard)
      .useValue({ canActivate: () => true })
      .overrideInterceptor(WebhookDedupeInterceptor)
      .useValue({ intercept: () => undefined })
      .compile();

    const legacyEvent = {
      id: 'evt_account_updated',
      type: 'account.updated' as const,
      account: 'acct_legacy',
      data: { object: { id: 'acct_from_object' } },
    } as Stripe.Event;

    await module.get(PaymentsController).handleWebhook({ stripeEvent: legacyEvent });

    expect(sync.execute).toHaveBeenCalledWith('acct_legacy');
  });

  it.each([
    'v2.core.account.updated',
    'v2.core.account.closed',
    'v2.core.account[configuration.recipient].updated',
    'v2.core.account[configuration.recipient].capability_status_updated',
    'v2.core.account[requirements].updated',
    'v2.core.account[future_requirements].updated',
  ] as const)('syncs the related account for %s', async (type) => {
    const sync = { execute: jest.fn().mockResolvedValue(right({ processed: true })) };
    const module = await Test.createTestingModule({
      controllers: [PaymentsController],
      providers: [
        { provide: CreatePaymentSessionUseCase, useValue: { execute: jest.fn() } },
        { provide: CreatePaymentIntentUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessGroupWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessRefundUseCase, useValue: { execute: jest.fn() } },
        { provide: StartConnectOnboardingUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectStatusUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectDashboardLinkUseCase, useValue: { execute: jest.fn() } },
        { provide: SyncConnectAccountUseCase, useValue: sync },
        { provide: RecoverDisputeTransferUseCase, useValue: { execute: jest.fn() } },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(WebhookGuard)
      .useValue({ canActivate: () => true })
      .overrideInterceptor(WebhookDedupeInterceptor)
      .useValue({ intercept: () => undefined })
      .compile();

    await module.get(PaymentsController).handleWebhook({ stripeEvent: event(type) });

    expect(sync.execute).toHaveBeenCalledWith('acct_1');
  });

  it.each([
    event('v2.core.account.updated', 'wrong.type'),
    event('v2.core.account.closed', 'missing.type'),
  ])('ignores malformed v2 account events', async (stripeEvent) => {
    const sync = { execute: jest.fn() };
    const module = await Test.createTestingModule({
      controllers: [PaymentsController],
      providers: [
        { provide: CreatePaymentSessionUseCase, useValue: { execute: jest.fn() } },
        { provide: CreatePaymentIntentUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessGroupWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessRefundUseCase, useValue: { execute: jest.fn() } },
        { provide: StartConnectOnboardingUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectStatusUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectDashboardLinkUseCase, useValue: { execute: jest.fn() } },
        { provide: SyncConnectAccountUseCase, useValue: sync },
        { provide: RecoverDisputeTransferUseCase, useValue: { execute: jest.fn() } },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(WebhookGuard)
      .useValue({ canActivate: () => true })
      .overrideInterceptor(WebhookDedupeInterceptor)
      .useValue({ intercept: () => undefined })
      .compile();

    await module.get(PaymentsController).handleWebhook({ stripeEvent });

    expect(sync.execute).not.toHaveBeenCalled();
  });
});

describe('PaymentsController dispute webhooks', () => {
  it.each(['charge.dispute.created', 'charge.dispute.closed'] as const)(
    'routes %s into durable payment recovery for its charge',
    async (type) => {
      const recovery = { execute: jest.fn().mockResolvedValue(right(undefined)) };
      const module = await Test.createTestingModule({
        controllers: [PaymentsController],
        providers: [
          { provide: CreatePaymentSessionUseCase, useValue: { execute: jest.fn() } },
          { provide: CreatePaymentIntentUseCase, useValue: { execute: jest.fn() } },
          { provide: ProcessWebhookUseCase, useValue: { execute: jest.fn() } },
          { provide: ProcessGroupWebhookUseCase, useValue: { execute: jest.fn() } },
          { provide: ProcessRefundUseCase, useValue: { execute: jest.fn() } },
          { provide: StartConnectOnboardingUseCase, useValue: { execute: jest.fn() } },
          { provide: GetConnectStatusUseCase, useValue: { execute: jest.fn() } },
          { provide: GetConnectDashboardLinkUseCase, useValue: { execute: jest.fn() } },
          { provide: SyncConnectAccountUseCase, useValue: { execute: jest.fn() } },
          { provide: RecoverDisputeTransferUseCase, useValue: recovery },
        ],
      })
        .overrideGuard(JwtAuthGuard)
        .useValue({ canActivate: () => true })
        .overrideGuard(WebhookGuard)
        .useValue({ canActivate: () => true })
        .overrideInterceptor(WebhookDedupeInterceptor)
        .useValue({ intercept: () => undefined })
        .compile();

       const disputeEvent = {
         id: `evt_${type}`,
         type,
         data: { object: { id: 'dp_1', charge: 'ch_1', ...(type.endsWith('closed') ? { status: 'lost' } : {}) } },
       } as Stripe.Event;

      await module.get(PaymentsController).handleWebhook({ stripeEvent: disputeEvent });

       expect(recovery.execute).toHaveBeenCalledWith('ch_1');
    },
  );

  it('does not recover a closed dispute won by FreeBay', async () => {
    const recovery = { execute: jest.fn().mockResolvedValue(right(undefined)) };
    const module = await Test.createTestingModule({
      controllers: [PaymentsController],
      providers: [
        { provide: CreatePaymentSessionUseCase, useValue: { execute: jest.fn() } },
        { provide: CreatePaymentIntentUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessGroupWebhookUseCase, useValue: { execute: jest.fn() } },
        { provide: ProcessRefundUseCase, useValue: { execute: jest.fn() } },
        { provide: StartConnectOnboardingUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectStatusUseCase, useValue: { execute: jest.fn() } },
        { provide: GetConnectDashboardLinkUseCase, useValue: { execute: jest.fn() } },
        { provide: SyncConnectAccountUseCase, useValue: { execute: jest.fn() } },
        { provide: RecoverDisputeTransferUseCase, useValue: recovery },
      ],
    })
      .overrideGuard(JwtAuthGuard).useValue({ canActivate: () => true })
      .overrideGuard(WebhookGuard).useValue({ canActivate: () => true })
      .overrideInterceptor(WebhookDedupeInterceptor).useValue({ intercept: () => undefined })
      .compile();

    const disputeEvent = {
      id: 'evt_dispute_won',
      type: 'charge.dispute.closed' as const,
      data: { object: { id: 'dp_1', charge: 'ch_1', status: 'won' } },
    } as Stripe.Event;

    await module.get(PaymentsController).handleWebhook({ stripeEvent: disputeEvent });

    expect(recovery.execute).not.toHaveBeenCalled();
  });
});
