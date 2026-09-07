import { DisputeResolutionExecutionService } from './dispute-resolution-execution.service';
import { WalletMissingError } from '@/shared/wallet/wallet-mutation';
import { DisputeWithOrder } from '../types/dispute.types';

describe('DisputeResolutionExecutionService', () => {
  let sut: DisputeResolutionExecutionService;

  beforeEach(() => {
    sut = new DisputeResolutionExecutionService();
  });

  function buildTx(walletExists = true, claimedCount = 1) {
    return {
      order: { updateMany: jest.fn().mockResolvedValue({ count: claimedCount }) },
      wallet: {
        findUnique: jest.fn().mockResolvedValue(walletExists ? { userId: 'seller-1' } : null),
        upsert: jest.fn().mockResolvedValue({}),
      },
      walletEntry: { createMany: jest.fn().mockResolvedValue({ count: 1 }) },
    } as unknown as Parameters<DisputeResolutionExecutionService['resolveInFavorOfBuyer']>[0];
  }

  function buildDispute(overrides: Partial<DisputeWithOrder['order']> = {}): DisputeWithOrder {
    return {
      id: 'dispute-1',
      orderId: 'order-1',
      order: {
        id: 'order-1',
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        amount: 10000,
        sellerAmount: 9000,
        ...overrides,
      },
    } as unknown as DisputeWithOrder;
  }

  describe('resolveInFavorOfBuyer', () => {
    it('claims the escrow, refunds the buyer, and releases the seller hold', async () => {
      const tx = buildTx();

      await sut.resolveInFavorOfBuyer(tx, buildDispute());

      expect(tx.order.updateMany).toHaveBeenCalledWith({
        where: { id: 'order-1', escrowStatus: 'HELD' },
        data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
      });
      expect(tx.wallet.upsert).toHaveBeenCalledWith({
        where: { userId: 'buyer-1' },
        create: { user: { connect: { id: 'buyer-1' } }, availableBalance: 10000 },
        update: { availableBalance: { increment: 10000 } },
      });
      expect(tx.wallet.upsert).toHaveBeenCalledWith({
        where: { userId: 'seller-1' },
        create: { user: { connect: { id: 'seller-1' } }, pendingBalance: -9000 },
        update: { pendingBalance: { increment: -9000 } },
      });
    });

    it('creates the buyer wallet when the refund lands on a user who never had one', async () => {
      const tx = buildTx();
      (tx.wallet.findUnique as jest.Mock).mockResolvedValue({ userId: 'seller-1' });

      await sut.resolveInFavorOfBuyer(tx, buildDispute());

      const buyerCall = (tx.wallet.upsert as jest.Mock).mock.calls.find(
        ([arg]) => arg.where.userId === 'buyer-1',
      );
      expect(buyerCall[0].create).toEqual({
        user: { connect: { id: 'buyer-1' } },
        availableBalance: 10000,
      });
    });

    it('refuses to release a hold against a seller wallet that does not exist', async () => {
      const tx = buildTx(false);

      await expect(sut.resolveInFavorOfBuyer(tx, buildDispute())).rejects.toThrow(WalletMissingError);
    });

    it('moves no money when the escrow was already released', async () => {
      const tx = buildTx(true, 0);

      await sut.resolveInFavorOfBuyer(tx, buildDispute());

      expect(tx.wallet.upsert).not.toHaveBeenCalled();
    });
  });

  describe('resolveInFavorOfSeller', () => {
    it('claims the escrow and moves sellerAmount from pending to available and totalEarned', async () => {
      const tx = buildTx();

      await sut.resolveInFavorOfSeller(tx, buildDispute());

      expect(tx.order.updateMany).toHaveBeenCalledWith({
        where: { id: 'order-1', escrowStatus: 'HELD' },
        data: { status: 'COMPLETED', escrowStatus: 'RELEASED' },
      });
      expect(tx.wallet.upsert).toHaveBeenCalledWith({
        where: { userId: 'seller-1' },
        create: {
          user: { connect: { id: 'seller-1' } },
          availableBalance: 9000,
          pendingBalance: -9000,
          totalEarned: 9000,
        },
        update: {
          availableBalance: { increment: 9000 },
          pendingBalance: { increment: -9000 },
          totalEarned: { increment: 9000 },
        },
      });
    });

    it('refuses to pay out against a seller wallet that does not exist', async () => {
      const tx = buildTx(false);

      await expect(sut.resolveInFavorOfSeller(tx, buildDispute())).rejects.toThrow(WalletMissingError);
    });

    it('moves no money when the escrow was already released', async () => {
      const tx = buildTx(true, 0);

      await sut.resolveInFavorOfSeller(tx, buildDispute());

      expect(tx.wallet.upsert).not.toHaveBeenCalled();
    });
  });
});
