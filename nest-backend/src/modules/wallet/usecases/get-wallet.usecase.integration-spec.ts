import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory } from '../../../../test/factories';
import { WalletDatabaseRepository } from '../data/repositories/wallet-database.repository';
import { GetWalletUseCase } from './get-wallet.usecase';

describe('GetWalletUseCase bootstrap integration', () => {
  let userFactory: UserFactory;
  let repository: WalletDatabaseRepository;
  let sut: GetWalletUseCase;

  beforeAll(() => {
    userFactory = new UserFactory(prisma);
    repository = new WalletDatabaseRepository(prisma as PrismaService);
    sut = new GetWalletUseCase(repository);
  });

  it('creates one zeroed wallet and no ledger entries across repeated bootstrap', async () => {
    const user = await userFactory.create();

    await Promise.all([
      sut.execute(user.id),
      sut.execute(user.id),
      sut.execute(user.id),
    ]);

    const wallets = await prisma.wallet.findMany({ where: { userId: user.id } });
    expect(wallets).toHaveLength(1);
    expect(wallets[0]).toMatchObject({
      userId: user.id,
      availableBalance: 0,
      pendingBalance: 0,
      totalEarned: 0,
    });
    expect(await prisma.walletEntry.count({ where: { userId: user.id } })).toBe(0);
  });
});
