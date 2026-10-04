import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { UserDatabaseRepository } from './user-database.repository';

describe('UserDatabaseRepository', () => {
  it('guards Apple credential rotation with the active-account predicate', async () => {
    const user = { update: jest.fn().mockResolvedValue({ id: 'user-1', deletedAt: null }) };
    const module = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: PrismaService, useValue: { user } },
      ],
    }).compile();
    const repository = module.get(UserDatabaseRepository);

    const result = await repository.updateAppleCredential('user-1', 'rotated-cipher');

    expect(user.update).toHaveBeenCalledWith({
      where: { id: 'user-1', deletedAt: null },
      data: { appleRefreshTokenEncrypted: 'rotated-cipher' },
    });
    expect(result.isRight()).toBe(true);
  });

  it('returns null when conditional Apple credential rotation matches no active account', async () => {
    const user = {
      update: jest.fn().mockRejectedValue(new Prisma.PrismaClientKnownRequestError('No matching record', {
        code: 'P2025',
        clientVersion: 'test',
      })),
    };
    const module = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: PrismaService, useValue: { user } },
      ],
    }).compile();
    const repository = module.get(UserDatabaseRepository);

    const result = await repository.updateAppleCredential('user-1', 'rotated-cipher');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toBeNull();
  });

  it('preserves unexpected conditional-update failures as repository errors', async () => {
    const user = { update: jest.fn().mockRejectedValue(new Error('Connection unavailable')) };
    const module = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: PrismaService, useValue: { user } },
      ],
    }).compile();
    const repository = module.get(UserDatabaseRepository);

    const result = await repository.updateAppleCredential('user-1', 'rotated-cipher');

    expect(result.isLeft()).toBe(true);
  });
});
