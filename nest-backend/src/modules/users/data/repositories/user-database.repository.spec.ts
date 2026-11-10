import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CpfProtectionService } from '@/shared/utils/cpf-protection.service';
import { UserDatabaseRepository } from '@/modules/users';

const cpfProtection = new CpfProtectionService(new ConfigService({
  CPF_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
  CPF_HMAC_KEY: Buffer.alloc(32, 2).toString('base64'),
}));

describe('UserDatabaseRepository', () => {
  it('guards Apple credential rotation with the active-account predicate', async () => {
    const user = { update: jest.fn().mockResolvedValue({ id: 'user-1', deletedAt: null }) };
    const module = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: CpfProtectionService, useValue: cpfProtection },
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
        { provide: CpfProtectionService, useValue: cpfProtection },
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
        { provide: CpfProtectionService, useValue: cpfProtection },
        { provide: PrismaService, useValue: { user } },
      ],
    }).compile();
    const repository = module.get(UserDatabaseRepository);

    const result = await repository.updateAppleCredential('user-1', 'rotated-cipher');

    expect(result.isLeft()).toBe(true);
  });

  it('stores ciphertext plus the stable CPF HMAC and returns plaintext only inside the owner repository', async () => {
    const create = jest.fn(async (args: { data: { cpf: string; cpfHash: string } }) => args.data);
    const module = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: CpfProtectionService, useValue: cpfProtection },
        { provide: PrismaService, useValue: { user: { create }, $queryRaw: jest.fn().mockResolvedValue([]) } },
      ],
    }).compile();

    const result = await module.get(UserDatabaseRepository).create({
      email: 'cpf@example.com', displayName: 'CPF', cpf: '529.982.247-25',
    });

    expect(create).toHaveBeenCalledTimes(1);
    const saved = create.mock.calls[0][0].data;
    expect(saved.cpf).not.toBe('52998224725');
    expect(saved.cpfHash).toMatch(/^v1:[0-9a-f]{64}$/);
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.cpf).toBe('52998224725');
  });

  it('rejects a duplicate matching legacy plaintext before writing', async () => {
    const create = jest.fn();
    const module = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: CpfProtectionService, useValue: cpfProtection },
        { provide: PrismaService, useValue: { user: { create }, $queryRaw: jest.fn().mockResolvedValue([{ id: 'legacy-user' }]) } },
      ],
    }).compile();

    const result = await module.get(UserDatabaseRepository).create({
      email: 'duplicate@example.com', displayName: 'Duplicate', cpf: '529.982.247-25',
    });

    expect(create).not.toHaveBeenCalled();
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.statusCode).toBe(409);
  });

  it('maps a concurrent HMAC unique-constraint race to the CPF conflict response', async () => {
    const create = jest.fn().mockRejectedValue(new Prisma.PrismaClientKnownRequestError('Unique conflict', {
      code: 'P2002', clientVersion: 'test', meta: { target: ['cpfHash'] },
    }));
    const module = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: CpfProtectionService, useValue: cpfProtection },
        { provide: PrismaService, useValue: { user: { create }, $queryRaw: jest.fn().mockResolvedValue([]) } },
      ],
    }).compile();

    const result = await module.get(UserDatabaseRepository).create({
      email: 'race@example.com', displayName: 'Race', cpf: '529.982.247-25',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.statusCode).toBe(409);
  });
});
