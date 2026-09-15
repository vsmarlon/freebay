import { Test } from '@nestjs/testing';
import { PaymentMethod, PaymentProvider, TransferDeliveryState, WalletEntryReason } from '@prisma/client';
import { prisma } from '../../../../../test/setup-integration';
import { OrderFactory, ProductFactory, UserFactory } from '../../../../../test/factories';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { TransactionDatabaseRepository } from './transaction-database.repository';

describe('Transaction transfer durability integration', () => {
  let transactions: TransactionDatabaseRepository;
  let users: UserFactory;
  let products: ProductFactory;
  let orders: OrderFactory;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      providers: [
        TransactionDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    transactions = module.get(TransactionDatabaseRepository);
    users = new UserFactory(prisma);
    products = new ProductFactory(prisma);
    orders = new OrderFactory(prisma);
  });

  async function createPendingTransfer() {
    const buyer = await users.create();
    const seller = await users.createWithWallet({}, { availableBalance: 1000 });
    const product = await products.createWithPrice(seller.id, 1000);
    const order = await orders.create(buyer.id, seller.id, product.id);
    const transaction = await prisma.transaction.create({
      data: {
        orderId: order.id,
        amount: 1000,
        platformFee: 100,
        sellerAmount: 900,
        paymentMethod: PaymentMethod.CREDIT_CARD,
        provider: PaymentProvider.STRIPE,
        idempotencyKey: `payment:${order.id}`,
        chargeId: 'ch_transfer',
      },
    });

    return { order, seller, transaction };
  }

  it('allows only one concurrent transfer claim and never steals an active lease', async () => {
    const { order, transaction } = await createPendingTransfer();
    const first = await transactions.claimTransfer(order.id, new Date('2026-09-14T10:00:00.000Z'));
    expect(first.isRight()).toBe(true);
    if (first.isRight()) expect(first.value.count).toBe(1);

    const concurrent = await Promise.all([
      transactions.claimTransfer(order.id, new Date('2026-09-14T10:01:00.000Z')),
      transactions.claimTransfer(order.id, new Date('2026-09-14T10:02:00.000Z')),
    ]);
    expect(concurrent.every((result) => result.isRight())).toBe(true);
    expect(concurrent.filter((result) => result.isRight() && result.value.count === 1)).toHaveLength(0);
    expect((await prisma.transaction.findUnique({ where: { id: transaction.id } }))?.transferState)
      .toBe(TransferDeliveryState.PROCESSING);
  });

  it('finalizes and debits the wallet once, including replay attempts', async () => {
    const { order, seller, transaction } = await createPendingTransfer();
    await transactions.claimTransfer(order.id, new Date());

    const finalize = async () => prisma.$transaction(async (tx) => {
      const result = await transactions.finalizeTransfer(transaction.id, 'tr_once', tx);
      if (result.isRight() && result.value.count === 1) {
        await applyWalletDelta(tx, seller.id, { availableBalance: -900 }, {
          reason: WalletEntryReason.PAYOUT,
          orderId: order.id,
          transferId: 'tr_once',
        });
      }
      return result;
    });

    const results = await Promise.all([finalize(), finalize()]);
    expect(results.filter((result) => result.isRight() && result.value.count === 1)).toHaveLength(1);
    const replay = await transactions.finalizeTransfer(transaction.id, 'tr_once', prisma);
    expect(replay.isRight()).toBe(true);
    if (replay.isRight()) expect(replay.value.count).toBe(0);

    const wallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
    const ledger = await prisma.walletEntry.findMany({ where: { userId: seller.id, orderId: order.id } });
    expect(wallet?.availableBalance).toBe(100);
    expect(ledger).toHaveLength(1);
    expect(ledger[0].amount).toBe(-900);
  });
});
