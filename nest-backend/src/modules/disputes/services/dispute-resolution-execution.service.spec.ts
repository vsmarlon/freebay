import { Test } from '@nestjs/testing';
import { Module } from '@nestjs/common';
import { ClsModule } from 'nestjs-cls';
import { ClsPluginTransactional } from '@nestjs-cls/transactional';
import { TransactionalAdapterPrisma } from '@nestjs-cls/transactional-adapter-prisma';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { createTransactionClient } from '@/shared/testing/test-doubles';
import { DisputeResolutionExecutionService } from './dispute-resolution-execution.service';
import { WalletMissingError } from '@/shared/wallet/wallet-mutation';
import { DisputeWithOrder } from '../types/dispute.types';

describe('DisputeResolutionExecutionService', () => {
  let sut: DisputeResolutionExecutionService;

  function buildRoute(walletExists = true, claimedCount = 1) {
    // The delegates object is what the interactive $transaction hands back as
    // the transaction client; the adapters see the calls and the assertions
    // made below. $transaction falls back to running the callback straight
    // away so the @Transactional wrapper behaves like the real client.
    const delegates = {
      dispute: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      order: { updateMany: jest.fn().mockResolvedValue({ count: claimedCount }) },
      transaction: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      wallet: {
        findUnique: jest.fn().mockResolvedValue(walletExists ? { userId: 'seller-1' } : null),
        createMany: jest.fn().mockResolvedValue({ count: 1 }),
        update: jest.fn().mockResolvedValue({}),
      },
      walletEntry: { createMany: jest.fn().mockResolvedValue({ count: 1 }) },
    };
    return {
      delegates,
      client: createTransactionClient(delegates),
      // The adapter opens the interactive transaction on this double; it
      // receives the delegates object as the transaction client.
      prismaDouble: {
        $transaction: jest.fn((fn: (c: unknown) => Promise<unknown>) => fn(delegates)),
      },
    };
  }

  async function compileSuite(walletExists = true, claimedCount = 1) {
    const build = buildRoute(walletExists, claimedCount);
    @Module({
      providers: [{ provide: PrismaService, useValue: build.prismaDouble }],
      exports: [PrismaService],
    })
    class FakePrismaModule {}
    const module = await Test.createTestingModule({
      imports: [
        ClsModule.forRoot({
          global: true,
          plugins: [
            new ClsPluginTransactional({
              adapter: new TransactionalAdapterPrisma({ prismaInjectionToken: PrismaService }),
              imports: [FakePrismaModule],
            }),
          ],
        }),
      ],
      providers: [DisputeResolutionExecutionService],
    }).compile();
    sut = module.get(DisputeResolutionExecutionService);
    return build.delegates;
  }

  function buildDispute(overrides: Partial<DisputeWithOrder['order']> = {}): DisputeWithOrder {
    const now = new Date();
    return {
      id: 'dispute-1',
      orderId: 'order-1',
      openedById: 'buyer-1',
      status: 'OPEN',
      reason: 'Item não recebido',
      buyerEvidence: null,
      sellerEvidence: null,
      resolution: null,
      resolvedAt: null,
      resolvedById: null,
      createdAt: now,
      expiresAt: now,
      order: {
        id: 'order-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        productId: 'product-1',
        quantity: 1,
        amount: 10000,
        platformFee: 1000,
        sellerAmount: 9000,
        status: 'DISPUTED',
        escrowStatus: 'HELD',
        meetingScheduledAt: null,
        deliveryConfirmedAt: null,
        cancellationReason: null,
        createdAt: now,
        updatedAt: now,
        ...overrides,
      },
    };
  }

  describe('finalizeBuyer', () => {
    it('claims the dispute, the escrow, records Stripe refund completion, and releases the seller hold without wallet-crediting the buyer', async () => {
      const fake = await compileSuite();

      await sut.finalizeBuyer(buildDispute(), {
        operationId: 'refund-op-1', providerId: 're_1', amount: 10000,
      }, { resolution: 'Buyer wins', resolvedById: null });

      expect(fake.order.updateMany).toHaveBeenCalledWith(expect.objectContaining({
        where: expect.objectContaining({ id: 'order-1', cancellationReason: 'DISPUTE_REFUND_PENDING' }),
      }));
      expect(fake.transaction.updateMany).toHaveBeenCalledWith(expect.objectContaining({
        where: expect.objectContaining({ refundOperationId: 'refund-op-1', refundProviderId: 're_1', refundAmount: 10000 }),
        data: { status: 'REFUNDED' },
      }));
      expect(fake.wallet.update).not.toHaveBeenCalledWith(expect.objectContaining({ where: { userId: 'buyer-1' } }));
      expect(fake.wallet.update).toHaveBeenCalledWith({
        where: { userId: 'seller-1' },
        data: { pendingBalance: { increment: -9000 } },
      });
    });

    it('does not create or credit a buyer wallet for a Stripe refund', async () => {
      const fake = await compileSuite();
      (fake.wallet.findUnique as jest.Mock).mockResolvedValue({ userId: 'seller-1' });

      await sut.finalizeBuyer(buildDispute(), {
        operationId: 'refund-op-1', providerId: 're_1', amount: 10000,
      }, { resolution: 'Buyer wins', resolvedById: null });

      const buyerCall = (fake.wallet.update as jest.Mock).mock.calls.find(
        ([arg]) => arg.where.userId === 'buyer-1',
      );
      expect(buyerCall).toBeUndefined();
    });

    it('refuses to release a hold against a seller wallet that does not exist', async () => {
      await compileSuite(false);

      await expect(sut.finalizeBuyer(buildDispute(), {
        operationId: 'refund-op-1', providerId: 're_1', amount: 10000,
      }, { resolution: 'Buyer wins', resolvedById: null })).rejects.toThrow(WalletMissingError);
    });

    it('moves no money when the escrow was already released', async () => {
      const fake = await compileSuite(true, 0);

      await expect(sut.finalizeBuyer(buildDispute(), {
        operationId: 'refund-op-1', providerId: 're_1', amount: 10000,
      }, { resolution: 'Buyer wins', resolvedById: null })).rejects.toThrow('DISPUTE_ORDER_CLAIM_LOST');

      expect(fake.wallet.update).not.toHaveBeenCalled();
    });
  });

  describe('finalizeSeller', () => {
    it('claims the escrow and moves sellerAmount from pending to available and totalEarned', async () => {
      const fake = await compileSuite();

      await sut.finalizeSeller(buildDispute(), { resolution: 'Seller wins', resolvedById: 'admin-1' });

      expect(fake.order.updateMany).toHaveBeenCalledWith({
        where: { id: 'order-1', status: 'DISPUTED', escrowStatus: 'HELD', cancellationReason: null },
        data: { status: 'COMPLETED', escrowStatus: 'RELEASED' },
      });
      expect(fake.wallet.update).toHaveBeenCalledWith({
        where: { userId: 'seller-1' },
        data: {
          availableBalance: { increment: 9000 },
          pendingBalance: { increment: -9000 },
          totalEarned: { increment: 9000 },
        },
      });
      expect(fake.transaction.updateMany).toHaveBeenCalledWith(expect.objectContaining({
        where: expect.objectContaining({ orderId: 'order-1', status: 'PAID' }),
        data: { status: 'RELEASED', releasedAt: expect.any(Date) },
      }));
    });

    it('refuses to pay out against a seller wallet that does not exist', async () => {
      await compileSuite(false);

      await expect(sut.finalizeSeller(buildDispute(), { resolution: 'Seller wins', resolvedById: null }))
        .rejects.toThrow(WalletMissingError);
    });

    it('moves no money when the escrow was already released', async () => {
      const fake = await compileSuite(true, 0);

      await expect(sut.finalizeSeller(buildDispute(), { resolution: 'Seller wins', resolvedById: null }))
        .rejects.toThrow('DISPUTE_ORDER_CLAIM_LOST');

      expect(fake.wallet.update).not.toHaveBeenCalled();
    });
  });
});
