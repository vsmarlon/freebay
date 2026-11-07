import { Test } from '@nestjs/testing';
import { left, right } from '@/shared/core/either';
import { EmailVerificationRequiredError, UserNotFoundError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';
import { EmailVerificationGateService } from './email-verification-gate.service';

describe('EmailVerificationGateService', () => {
  async function compile(findById: jest.Mock) {
    const module = await Test.createTestingModule({
      providers: [
        EmailVerificationGateService,
        { provide: UserDatabaseRepository, useValue: { findById } },
      ],
    }).compile();
    return module.get(EmailVerificationGateService);
  }

  it('allows a verified account through', async () => {
    const sut = await compile(jest.fn().mockResolvedValue(right({ id: 'u1', emailVerified: true })));

    expect(await sut.ensureVerified('u1')).toEqual(right(undefined));
  });

  it('blocks an unverified account with the verification-required error', async () => {
    const sut = await compile(jest.fn().mockResolvedValue(right({ id: 'u1', emailVerified: false })));

    expect(await sut.ensureVerified('u1')).toEqual(left(new EmailVerificationRequiredError()));
  });

  it('fails controlled when the account does not exist', async () => {
    const sut = await compile(jest.fn().mockResolvedValue(right(null)));

    expect(await sut.ensureVerified('u1')).toEqual(left(new UserNotFoundError()));
  });
});
