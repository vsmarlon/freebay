import { WalletEntryReason } from '@prisma/client';
import { prisma } from '../../../test/setup-integration';
import { UserFactory } from '../../../test/factories';
import { applyWalletDelta, WalletMissingError } from './wallet-mutation';

describe('applyWalletDelta Integration', () => {
  let userFactory: UserFactory;

  beforeAll(() => {
    userFactory = new UserFactory(prisma);
  });

  async function balances(userId: string) {
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    return {
      available: wallet?.availableBalance ?? 0,
      pending: wallet?.pendingBalance ?? 0,
      totalEarned: wallet?.totalEarned ?? 0,
    };
  }

  it('creates the wallet on first credit and records one ledger entry per field', async () => {
    const user = await userFactory.create();

    await prisma.$transaction((tx) =>
      applyWalletDelta(tx, user.id, { pendingBalance: 9000 }, { reason: WalletEntryReason.SALE_HELD }),
    );

    expect(await balances(user.id)).toEqual({ available: 0, pending: 9000, totalEarned: 0 });

    const entries = await prisma.walletEntry.findMany({ where: { userId: user.id } });
    expect(entries).toHaveLength(1);
    expect(entries[0].amount).toBe(9000);
    expect(entries[0].kind).toBe('PENDING');
  });

  it('refuses to debit a wallet that does not exist', async () => {
    const user = await userFactory.create();

    await expect(
      prisma.$transaction((tx) =>
        applyWalletDelta(
          tx,
          user.id,
          { pendingBalance: -100 },
          { reason: WalletEntryReason.HOLD_RELEASED },
        ),
      ),
    ).rejects.toThrow(WalletMissingError);

    expect(await prisma.walletEntry.count({ where: { userId: user.id } })).toBe(0);
  });

  it('keeps the ledger equal to the balance under concurrent credits', async () => {
    const user = await userFactory.create();
    const concurrency = Number(process.env.WALLET_CONCURRENCY ?? 20);
    const credits = Array.from({ length: concurrency }, () =>
      prisma.$transaction((tx) =>
        applyWalletDelta(
          tx,
          user.id,
          { availableBalance: 500 },
          { reason: WalletEntryReason.SALE_RELEASED },
        ),
      ),
    );

    await Promise.all(credits);

    const walletCount = await prisma.wallet.count({ where: { userId: user.id } });
    const { available } = await balances(user.id);
    const sum = await prisma.walletEntry.aggregate({
      where: { userId: user.id, kind: 'AVAILABLE' },
      _sum: { amount: true },
    });

    expect(walletCount).toBe(1);
    expect(available).toBe(concurrency * 500);
    expect(sum._sum.amount).toBe(available);
  });

  it('keeps concurrent credits safe when the wallet already exists', async () => {
    const user = await userFactory.createWithWallet();
    const credits = Array.from({ length: 20 }, () =>
      prisma.$transaction((tx) =>
        applyWalletDelta(
          tx,
          user.id,
          { availableBalance: 500 },
          { reason: WalletEntryReason.SALE_RELEASED },
        ),
      ),
    );

    await Promise.all(credits);

    const { available } = await balances(user.id);
    expect(available).toBe(10000);
  });

  it('rolls the ledger entry back when the surrounding transaction fails', async () => {
    const user = await userFactory.create();

    await expect(
      prisma.$transaction(async (tx) => {
        await applyWalletDelta(
          tx,
          user.id,
          { availableBalance: 700 },
          { reason: WalletEntryReason.REFUND },
        );
        throw new Error('BOOM');
      }),
    ).rejects.toThrow('BOOM');

    expect(await balances(user.id)).toEqual({ available: 0, pending: 0, totalEarned: 0 });
    expect(await prisma.walletEntry.count({ where: { userId: user.id } })).toBe(0);
  });
});
