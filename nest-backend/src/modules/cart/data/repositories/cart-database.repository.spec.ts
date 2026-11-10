import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { CpfProtectionService } from '@/shared/utils/cpf-protection.service';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CartDatabaseRepository } from './cart-database.repository';

describe('CartDatabaseRepository CPF lookup', () => {
  const protection = new CpfProtectionService(new ConfigService({
    CPF_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
    CPF_HMAC_KEY: Buffer.alloc(32, 2).toString('base64'),
  }));

  it('decrypts encrypted CPF for checkout and never treats legacy plaintext as CPF', async () => {
    const cpf = protection.protect('52998224725').cpf;
    const findUnique = jest.fn().mockResolvedValue({ cpf });
    const module = await Test.createTestingModule({
      providers: [
        CartDatabaseRepository,
        { provide: CpfProtectionService, useValue: protection },
        { provide: PrismaService, useValue: { user: { findUnique } } },
      ],
    }).compile();
    const repository = module.get(CartDatabaseRepository);

    const encrypted = await repository.findUserCpf('owner');
    expect(encrypted.isRight()).toBe(true);
    if (encrypted.isRight()) expect(encrypted.value).toBe('52998224725');

    findUnique.mockResolvedValue({ cpf: '52998224725' });
    const legacy = await repository.findUserCpf('legacy-owner');
    expect(legacy.isRight()).toBe(true);
    if (legacy.isRight()) expect(legacy.value).toBeNull();
  });
});
