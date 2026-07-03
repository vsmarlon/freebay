import { DisputeResolutionExecutionService } from './dispute-resolution-execution.service';
import { DisputeWithOrder } from '../repositories/dispute.repository';

describe('DisputeResolutionExecutionService', () => {
  let sut: DisputeResolutionExecutionService;

  beforeEach(() => {
    sut = new DisputeResolutionExecutionService();
  });

  function buildTx(walletRow: { availableBalance: number; pendingBalance: number; totalEarned: number } | null) {
    return {
      order: { update: jest.fn().mockResolvedValue({}) },
      wallet: {
        findUnique: jest.fn().mockResolvedValue(walletRow),
        update: jest.fn().mockResolvedValue({}),
      },
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
    it('sets order to CANCELLED, escrow to REFUNDED, and credits buyer availableBalance by order.amount', async () => {
      const tx = buildTx({ availableBalance: 5000, pendingBalance: 0, totalEarned: 0 });
      const dispute = buildDispute();

      await sut.resolveInFavorOfBuyer(tx, dispute);

      expect(tx.order.update).toHaveBeenCalledWith({
        where: { id: 'order-1' },
        data: { status: 'CANCELLED', escrowStatus: 'REFUNDED' },
      });
      expect(tx.wallet.update).toHaveBeenCalledWith({
        where: { userId: 'buyer-1' },
        data: { availableBalance: { increment: 10000 } },
      });
    });

    it('skips wallet update when buyer wallet does not exist', async () => {
      const tx = buildTx(null);
      const dispute = buildDispute();

      await sut.resolveInFavorOfBuyer(tx, dispute);

      expect(tx.wallet.update).not.toHaveBeenCalled();
      expect(tx.order.update).toHaveBeenCalled();
    });
  });

  describe('resolveInFavorOfSeller', () => {
    it('sets order to COMPLETED, escrow to RELEASED, and moves sellerAmount from pendingBalance to availableBalance and totalEarned', async () => {
      const tx = buildTx({ availableBalance: 2000, pendingBalance: 9000, totalEarned: 0 });
      const dispute = buildDispute();

      await sut.resolveInFavorOfSeller(tx, dispute);

      expect(tx.order.update).toHaveBeenCalledWith({
        where: { id: 'order-1' },
        data: { status: 'COMPLETED', escrowStatus: 'RELEASED' },
      });
      expect(tx.wallet.update).toHaveBeenCalledWith({
        where: { userId: 'seller-1' },
        data: {
          pendingBalance: { decrement: 9000 },
          availableBalance: { increment: 9000 },
          totalEarned: { increment: 9000 },
        },
      });
    });

    it('skips wallet update when seller wallet does not exist', async () => {
      const tx = buildTx(null);
      const dispute = buildDispute();

      await sut.resolveInFavorOfSeller(tx, dispute);

      expect(tx.wallet.update).not.toHaveBeenCalled();
      expect(tx.order.update).toHaveBeenCalled();
    });
  });
});
