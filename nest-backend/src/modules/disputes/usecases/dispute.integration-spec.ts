import { Test, TestingModule } from '@nestjs/testing';
import { Provider, Type } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { Effect, Layer, TestClock, Clock, TestContext } from 'effect';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory, ProductFactory, OrderFactory } from '../../../../test/factories';
;
import { BadRequestError, UnauthorizedError, NotFoundError } from '@/shared/core/errors';
import { OpenDisputeUseCase } from './open-dispute.usecase';
import { ResolveDisputeUseCase } from './resolve-dispute.usecase';
import { SubmitEvidenceUseCase } from './submit-evidence.usecase';
import { WithdrawDisputeUseCase } from './withdraw-dispute.usecase';
import { PrismaDisputeRepository } from '../data/repositories/dispute-database.repository';
import { DisputeTransitionPolicy } from '../services/dispute-transition.policy';
import { DisputeResolutionExecutionService } from '../services/dispute-resolution-execution.service';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { PrismaTag, NotificationTag, NotificationServiceShape } from '../effect-harness/tags';
import { TestNotificationsLayer, RecordedNotification } from '../effect-harness/test-notifications.layer';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { DisputeCleanupTask } from '@/modules/tasks/dispute-cleanup.task';

const ONE_HOUR_MS = 60 * 60 * 1000;

describe('Disputes Effect Integration', () => {
  let userFactory: UserFactory;
  let productFactory: ProductFactory;
  let orderFactory: OrderFactory;
  let notifications: RecordedNotification[];

  beforeAll(() => {
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
    orderFactory = new OrderFactory(prisma);
  });

  beforeEach(() => {
    notifications = [];
  });

  function buildLayer() {
    return Layer.merge(
      Layer.sync(PrismaTag, () => prisma),
      TestNotificationsLayer(notifications),
    );
  }

  function run<A, E>(effect: Effect.Effect<A, E, PrismaTag | NotificationTag>) {
    return Effect.runPromise(
      effect.pipe(Effect.provide(buildLayer())),
    );
  }

  async function buildUsecase<T>(
    usecase: Type<T>,
    overrides: Provider[] = [],
    prismaClient: PrismaClient = prisma,
  ): Promise<T> {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        usecase,
        PrismaDisputeRepository,
        DisputeTransitionPolicy,
        DisputeResolutionExecutionService,
        { provide: PrismaService, useValue: prismaClient },
        { provide: NotificationService, useValue: notificationDouble() },
        ...overrides,
      ],
    }).compile();

    return module.get(usecase);
  }

  function notificationDouble(): NotificationServiceShape {
    return {
      notifyDispute: jest.fn().mockResolvedValue(undefined),
      notifyOrderStatus: jest.fn().mockResolvedValue(undefined),
      create: jest.fn().mockResolvedValue({ id: 'mock-notification-id' }),
    };
  }

  describe('OpenDisputeUseCase — 48h window', () => {
    const seed = () =>
      Effect.gen(function* () {
        const db = yield* PrismaTag;
        const buyer = yield* Effect.promise(() => userFactory.createWithWallet());
        const seller = yield* Effect.promise(() => userFactory.createWithWallet());
        const product = yield* Effect.promise(() => productFactory.create(seller.id));
        return { db, buyer, seller, product };
      });

    function makeUsecase(prismaClient: PrismaClient, notif: NotificationServiceShape) {
      return buildUsecase(
        OpenDisputeUseCase,
        [{ provide: NotificationService, useValue: notif }],
        prismaClient,
      );
    }

    it('succeeds 47h59m after delivery', async () => {
      const program = Effect.gen(function* () {
        const { db, buyer, product } = yield* seed();
        const deliveryTime = new Date(Date.now() - (47 * ONE_HOUR_MS + 59 * 60 * 1000));

        const order = yield* Effect.promise(() =>
          orderFactory.create(buyer.id, product.sellerId, product.id, {
            status: 'DELIVERED',
            deliveryConfirmedAt: deliveryTime,
          }),
        );

        const notif = yield* NotificationTag;
        const uc = yield* Effect.promise(() => makeUsecase(db, notif));
        const result = yield* Effect.promise(() =>
          uc.execute(
            { orderId: order.id, userId: buyer.id, reason: 'Within window' },
            new Date(),
          ),
        );

        expect(result.isRight()).toBe(true);
        expect(notifications.length).toBe(3);
        expect(notifications.filter(n => n.method === 'notifyDispute').length).toBe(1);
        expect(notifications.filter(n => n.method === 'notifyOrderStatus').length).toBe(2);
      });
      await run(program);
    });

    it('rejects 48h01m after delivery', async () => {
      const program = Effect.gen(function* () {
        const { db, buyer, product } = yield* seed();
        const deliveryTime = new Date(Date.now() - (48 * ONE_HOUR_MS + ONE_HOUR_MS));

        const order = yield* Effect.promise(() =>
          orderFactory.create(buyer.id, product.sellerId, product.id, {
            status: 'DELIVERED',
            deliveryConfirmedAt: deliveryTime,
          }),
        );

        const notif = yield* NotificationTag;
        const uc = yield* Effect.promise(() => makeUsecase(db, notif));
        const result = yield* Effect.promise(() =>
          uc.execute(
            { orderId: order.id, userId: buyer.id, reason: 'Too late' },
            new Date(Date.now()),
          ),
        );

        expect(result.isLeft()).toBe(true);
        if (result.isLeft()) {
          expect(result.value).toBeInstanceOf(BadRequestError);
        }

        const dispute = yield* Effect.promise(() =>
          prisma.dispute.findUnique({ where: { orderId: order.id } }),
        );
        expect(dispute).toBeNull();
      });
      await run(program);
    });

    it('rejects non-participant', async () => {
      const program = Effect.gen(function* () {
        const { db, buyer, product } = yield* seed();
        const stranger = yield* Effect.promise(() => userFactory.create());

        const order = yield* Effect.promise(() =>
          orderFactory.create(buyer.id, product.sellerId, product.id, {
            status: 'DELIVERED',
            deliveryConfirmedAt: new Date(),
          }),
        );

        const notif = yield* NotificationTag;
        const uc = yield* Effect.promise(() => makeUsecase(db, notif));
        const result = yield* Effect.promise(() =>
          uc.execute({ orderId: order.id, userId: stranger.id, reason: 'Hacker' }),
        );

        expect(result.isLeft()).toBe(true);
        if (result.isLeft()) {
          expect(result.value).toBeInstanceOf(UnauthorizedError);
        }
      });
      await run(program);
    });
  });

  describe('OpenDisputeUseCase — TestClock demo', () => {
    it('produces deterministic time advancement', async () => {
      const program = Effect.gen(function* () {
        yield* TestClock.setTime(new Date(1_000_000_000_000));
        yield* TestClock.adjust('48 hours');
        return yield* Clock.currentTimeMillis;
      });

      const result = await Effect.runPromise(
        program.pipe(Effect.provide(TestContext.TestContext)),
      );
      expect(result).toBe(1_000_000_000_000 + 48 * ONE_HOUR_MS);
    });
  });

  describe('ResolveDisputeUseCase — double-resolve guard', () => {
    async function seed() {
      const buyer = await userFactory.createWithWallet({}, { availableBalance: 5000 });
      const seller = await userFactory.createWithWallet({}, { pendingBalance: 9000, availableBalance: 2000 });
      const product = await productFactory.create(seller.id, { price: 10000 });
      const order = await orderFactory.create(buyer.id, seller.id, product.id, {
        status: 'DISPUTED',
        escrowStatus: 'HELD',
      });
      const dispute = await prisma.dispute.create({
        data: {
          orderId: order.id,
          openedById: buyer.id,
          reason: 'Test',
          status: 'OPEN',
          expiresAt: new Date(Date.now() + 72 * ONE_HOUR_MS),
        },
      });
      return { buyer, seller, order, dispute };
    }

    function makeUsecase() {
      return buildUsecase(ResolveDisputeUseCase, [
        {
          provide: SellerPayoutService,
          useValue: { payoutForOrder: jest.fn(), reverseForOrder: jest.fn() },
        },
      ]);
    }

    it('resolves in seller favor and updates wallet', async () => {
      const { seller, dispute } = await seed();
      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        resolution: 'Seller wins',
        winner: 'SELLER',
      });

      expect(result.isRight()).toBe(true);

      const wallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
      expect(wallet?.availableBalance).toBe(2000 + 9000);
      expect(wallet?.pendingBalance).toBe(0);
      expect(wallet?.totalEarned).toBe(9000);
    });

    it('resolves in buyer favor and refunds wallet', async () => {
      const { buyer, dispute } = await seed();
      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        resolution: 'Buyer wins',
        winner: 'BUYER',
      });

      expect(result.isRight()).toBe(true);

      const wallet = await prisma.wallet.findUnique({ where: { userId: buyer.id } });
      expect(wallet?.availableBalance).toBe(5000 + 10000);

      const dbOrder = await prisma.order.findUnique({ where: { id: dispute.orderId } });
      expect(dbOrder?.status).toBe('CANCELLED');
      expect(dbOrder?.escrowStatus).toBe('REFUNDED');
    });

    it('rejects resolving an already-resolved dispute', async () => {
      const { seller, dispute } = await seed();
      const uc = await makeUsecase();

      const first = await uc.execute({
        disputeId: dispute.id,
        resolution: 'Seller wins',
        winner: 'SELLER',
      });
      expect(first.isRight()).toBe(true);

      const second = await uc.execute({
        disputeId: dispute.id,
        resolution: 'Seller wins again',
        winner: 'SELLER',
      });

      expect(second.isLeft()).toBe(true);
      if (second.isLeft()) {
        expect(second.value).toBeInstanceOf(BadRequestError);
      }

      const wallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
      expect(wallet?.availableBalance).toBe(2000 + 9000);
      expect(wallet?.pendingBalance).toBe(0);
    });

    it('rejects resolving a withdrawn (CANCELLED) dispute', async () => {
      const { seller, dispute } = await seed();
      await prisma.dispute.update({ where: { id: dispute.id }, data: { status: 'CANCELLED' } });

      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        resolution: 'Seller wins',
        winner: 'SELLER',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }

      const wallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
      expect(wallet?.pendingBalance).toBe(9000);
      expect(wallet?.availableBalance).toBe(2000);
    });
  });

  describe('SubmitEvidenceUseCase — status transitions', () => {
    async function seed() {
      const buyer = await userFactory.createWithWallet();
      const seller = await userFactory.createWithWallet();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.create(buyer.id, seller.id, product.id, {
        status: 'DISPUTED',
        escrowStatus: 'HELD',
      });
      const dispute = await prisma.dispute.create({
        data: {
          orderId: order.id,
          openedById: buyer.id,
          reason: 'Test',
          status: 'OPEN',
          expiresAt: new Date(Date.now() + 72 * ONE_HOUR_MS),
        },
      });
      return { buyer, seller, order, dispute };
    }

    function makeUsecase() {
      return buildUsecase(SubmitEvidenceUseCase);
    }

    it('sets AWAITING_SELLER when buyer submits', async () => {
      const { dispute } = await seed();
      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        userId: dispute.openedById,
        evidence: { message: 'Buyer evidence' },
      });

      expect(result.isRight()).toBe(true);

      const db = await prisma.dispute.findUnique({ where: { id: dispute.id } });
      expect(db?.status).toBe('AWAITING_SELLER');
      expect(db?.buyerEvidence).toEqual({ message: 'Buyer evidence' });
    });

    it('sets AWAITING_BUYER when seller submits', async () => {
      const { dispute, seller } = await seed();
      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        userId: seller.id,
        evidence: { message: 'Seller evidence' },
      });

      expect(result.isRight()).toBe(true);

      const db = await prisma.dispute.findUnique({ where: { id: dispute.id } });
      expect(db?.status).toBe('AWAITING_BUYER');
      expect(db?.sellerEvidence).toEqual({ message: 'Seller evidence' });
    });

    it('rejects non-participant', async () => {
      const { dispute } = await seed();
      const stranger = await userFactory.create();
      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        userId: stranger.id,
        evidence: { message: 'Hacker' },
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(UnauthorizedError);
      }
    });

    it('rejects evidence after dispute is resolved', async () => {
      const { dispute } = await seed();
      await prisma.dispute.update({
        where: { id: dispute.id },
        data: { status: 'RESOLVED', resolution: 'Done', resolvedAt: new Date() },
      });

      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        userId: dispute.openedById,
        evidence: { message: 'Too late' },
      });

      expect(result.isLeft()).toBe(true);
    });

    it('rejects evidence after dispute is withdrawn (CANCELLED)', async () => {
      const { dispute } = await seed();
      await prisma.dispute.update({
        where: { id: dispute.id },
        data: { status: 'CANCELLED' },
      });

      const result = await (await makeUsecase()).execute({
        disputeId: dispute.id,
        userId: dispute.openedById,
        evidence: { message: 'Too late' },
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });
  });

  describe('DisputeCleanupTask — auto-expiry', () => {
    it('auto-resolves expired dispute in seller favor', async () => {
      const buyer = await userFactory.createWithWallet({}, { availableBalance: 5000 });
      const seller = await userFactory.createWithWallet({}, { pendingBalance: 9000, availableBalance: 2000 });
      const product = await productFactory.create(seller.id, { price: 10000 });
      const order = await orderFactory.create(buyer.id, seller.id, product.id, {
        status: 'DISPUTED',
        escrowStatus: 'HELD',
      });
      await prisma.dispute.create({
        data: {
          orderId: order.id,
          openedById: buyer.id,
          reason: 'Auto-expiry test',
          status: 'OPEN',
          expiresAt: new Date(Date.now() - ONE_HOUR_MS),
        },
      });

      const task = await buildUsecase(DisputeCleanupTask);
      await task.cleanupExpiredDisputes();

      const dbDispute = await prisma.dispute.findFirst({
        where: { orderId: order.id },
        orderBy: { createdAt: 'desc' },
      });
      expect(dbDispute?.status).toBe('RESOLVED');
      expect(dbDispute?.resolution).toContain('Auto-resolved');

      const dbOrder = await prisma.order.findUnique({ where: { id: order.id } });
      expect(dbOrder?.status).toBe('COMPLETED');
      expect(dbOrder?.escrowStatus).toBe('RELEASED');

      const sellerWallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
      expect(sellerWallet?.pendingBalance).toBe(0);
      expect(sellerWallet?.availableBalance).toBe(2000 + 9000);
      expect(sellerWallet?.totalEarned).toBe(9000);

      const buyerWallet = await prisma.wallet.findUnique({ where: { userId: buyer.id } });
      expect(buyerWallet?.availableBalance).toBe(5000);
    });

    it('does not touch non-expired disputes', async () => {
      const buyer = await userFactory.createWithWallet();
      const seller = await userFactory.createWithWallet();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.create(buyer.id, seller.id, product.id, {
        status: 'DISPUTED',
      });
      await prisma.dispute.create({
        data: {
          orderId: order.id,
          openedById: buyer.id,
          reason: 'Not expired',
          status: 'OPEN',
          expiresAt: new Date(Date.now() + 72 * ONE_HOUR_MS),
        },
      });

      const task = await buildUsecase(DisputeCleanupTask);
      await task.cleanupExpiredDisputes();

      const db = await prisma.dispute.findFirst({
        where: { orderId: order.id },
        orderBy: { createdAt: 'desc' },
      });
      expect(db?.status).toBe('OPEN');
    });
  });

  describe('WithdrawDisputeUseCase', () => {
    async function seed() {
      const buyer = await userFactory.createWithWallet();
      const seller = await userFactory.createWithWallet();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.create(buyer.id, seller.id, product.id, {
        status: 'DISPUTED',
        escrowStatus: 'HELD',
      });
      const dispute = await prisma.dispute.create({
        data: {
          orderId: order.id,
          openedById: buyer.id,
          reason: 'Test',
          status: 'OPEN',
          expiresAt: new Date(Date.now() + 72 * ONE_HOUR_MS),
        },
      });
      return { buyer, seller, order, dispute };
    }

    function makeUsecase() {
      return buildUsecase(WithdrawDisputeUseCase);
    }

    it('withdraws dispute, cancels it, and restores order to DELIVERED with escrow HELD', async () => {
      const { buyer, order, dispute } = await seed();

      const result = await (await makeUsecase()).execute({ disputeId: dispute.id, userId: buyer.id });

      expect(result.isRight()).toBe(true);

      const dbDispute = await prisma.dispute.findUnique({ where: { id: dispute.id } });
      expect(dbDispute?.status).toBe('CANCELLED');

      const dbOrder = await prisma.order.findUnique({ where: { id: order.id } });
      expect(dbOrder?.status).toBe('DELIVERED');
      expect(dbOrder?.escrowStatus).toBe('HELD');
    });

    it('returns UnauthorizedError when userId is not the dispute opener', async () => {
      const { seller, dispute } = await seed();

      const result = await (await makeUsecase()).execute({ disputeId: dispute.id, userId: seller.id });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(UnauthorizedError);
      }
    });

    it('returns BadRequestError when dispute is already RESOLVED', async () => {
      const { buyer, dispute } = await seed();
      await prisma.dispute.update({ where: { id: dispute.id }, data: { status: 'RESOLVED' } });

      const result = await (await makeUsecase()).execute({ disputeId: dispute.id, userId: buyer.id });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });

    it('returns BadRequestError when dispute is already CANCELLED (double-withdraw guard)', async () => {
      const { buyer, dispute } = await seed();
      await prisma.dispute.update({ where: { id: dispute.id }, data: { status: 'CANCELLED' } });

      const result = await (await makeUsecase()).execute({ disputeId: dispute.id, userId: buyer.id });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });

    it('returns NotFoundError when dispute does not exist', async () => {
      const { buyer } = await seed();

      const result = await (await makeUsecase()).execute({ disputeId: 'does-not-exist', userId: buyer.id });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });
});
