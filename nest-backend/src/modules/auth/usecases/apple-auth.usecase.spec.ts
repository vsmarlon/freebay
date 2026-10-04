import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { right } from '@/shared/core/either';
import { InvalidAppleTokenError } from '@/shared/core/errors';
import { AppleProviderService } from '@/shared/auth/apple-provider.service';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { SessionTokenService } from '../services/session-token.service';
import { AppleAuthUseCase } from './apple-auth.usecase';

describe('AppleAuthUseCase', () => {
  const identity = { sub: 'apple-sub', email: ' Person@Example.com ', emailVerified: true, nonce: 'hash' };
  const encrypted = 'iv.tag.cipher';
  const profile = {
    id: 'user-1', displayName: 'Person', username: null, email: 'person@example.com', passwordHash: null,
    appleId: 'apple-sub', appleRefreshTokenEncrypted: encrypted, googleId: null, emailVerified: true,
    cpfHash: null, phone: null, phoneVerified: false, city: null, state: null, avatarUrl: null, bio: null,
    isVerified: false, isGuest: false, role: UserRole.USER, reputationScore: 0, totalReviews: 0,
    createdAt: new Date(), updatedAt: new Date(), deletedAt: null, suspendedAt: null, suspensionReason: null,
  };
  let sut: AppleAuthUseCase;
  let users: {
    findByAppleId: jest.Mock;
    findByEmail: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
    updateAppleCredential: jest.Mock;
  };
  let apple: { verifyIdentityToken: jest.Mock; exchangeAuthorizationCode: jest.Mock };
  let tokens: { generate: jest.Mock };

  beforeEach(async () => {
    users = {
      findByAppleId: jest.fn().mockResolvedValue(right(null)),
      findByEmail: jest.fn().mockResolvedValue(right(null)),
      create: jest.fn().mockResolvedValue(right(profile)),
      update: jest.fn().mockResolvedValue(right(profile)),
      updateAppleCredential: jest.fn().mockResolvedValue(right(profile)),
    };
    apple = {
      verifyIdentityToken: jest.fn().mockResolvedValue(identity),
      exchangeAuthorizationCode: jest.fn().mockResolvedValue({ identity, encryptedRefreshToken: encrypted }),
    };
    tokens = { generate: jest.fn().mockReturnValue({ token: 'access-token', refreshToken: 'session-refresh' }) };
    const module = await Test.createTestingModule({ providers: [
      AppleAuthUseCase,
      { provide: UserDatabaseRepository, useValue: users },
      { provide: AppleProviderService, useValue: apple },
      { provide: SessionTokenService, useValue: tokens },
    ] }).compile();
    sut = module.get(AppleAuthUseCase);
  });

  const input = { identityToken: 'identity', authorizationCode: 'one-time-code', rawNonce: 'nonce' };

  it('creates a verified account from Apple’s verified email and returns only session data', async () => {
    const result = await sut.execute({ ...input, fullName: 'Person' });
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.user.displayName).toBe('Person');
      expect(result.value.token).toBe('access-token');
      expect(JSON.stringify(result.value)).not.toContain(encrypted);
      expect(JSON.stringify(result.value)).not.toContain('apple-sub');
    }
    expect(users.create).toHaveBeenCalledWith(expect.objectContaining({
      email: 'person@example.com', appleId: 'apple-sub', appleRefreshTokenEncrypted: encrypted,
      emailVerified: true, passwordHash: null, wallet: { create: {} },
    }));
    expect(tokens.generate).toHaveBeenCalledTimes(1);
  });

  it('rejects a returned identity-token subject mismatch without creating an account or session', async () => {
    apple.exchangeAuthorizationCode.mockResolvedValue({
      identity: { ...identity, sub: 'different-sub' }, encryptedRefreshToken: encrypted,
    });
    const result = await sut.execute(input);
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('INVALID_APPLE_TOKEN');
    expect(users.create).not.toHaveBeenCalled();
    expect(tokens.generate).not.toHaveBeenCalled();
  });

  it('does not silently link a verified Apple email to an existing password account', async () => {
    users.findByEmail.mockResolvedValue(right({ id: 'password-user', email: 'person@example.com' }));
    const result = await sut.execute(input);
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('APPLE_EMAIL_COLLISION');
    expect(users.update).not.toHaveBeenCalled();
    expect(users.create).not.toHaveBeenCalled();
    expect(tokens.generate).not.toHaveBeenCalled();
  });

  it('allows an existing Apple identity to sign in without a newly returned email', async () => {
    apple.exchangeAuthorizationCode.mockResolvedValue({
      identity: { sub: identity.sub, nonce: identity.nonce }, encryptedRefreshToken: 'rotated-cipher',
    });
    users.findByAppleId.mockResolvedValue(right(profile));
    const result = await sut.execute(input);
    expect(result.isRight()).toBe(true);
    expect(users.updateAppleCredential).toHaveBeenCalledWith(profile.id, 'rotated-cipher');
    expect(tokens.generate).toHaveBeenCalledTimes(1);
    expect(users.findByEmail).not.toHaveBeenCalled();
  });

  it('allows Apple reauthentication while deletion is pending but not yet effective', async () => {
    users.findByAppleId.mockResolvedValue(right({ ...profile, deletionRequestedAt: new Date() }));

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(users.updateAppleCredential).toHaveBeenCalledWith(profile.id, encrypted);
    expect(tokens.generate).toHaveBeenCalledTimes(1);
  });

  it('rejects identities without a verified email and creates no session', async () => {
    apple.exchangeAuthorizationCode.mockResolvedValue({
      identity: { sub: identity.sub, nonce: identity.nonce, email: identity.email, emailVerified: false },
      encryptedRefreshToken: encrypted,
    });
    const result = await sut.execute(input);
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('INVALID_APPLE_TOKEN');
    expect(users.create).not.toHaveBeenCalled();
    expect(tokens.generate).not.toHaveBeenCalled();
  });

  it('does not create a session for a removed Apple account', async () => {
    users.findByAppleId.mockResolvedValue(right({ ...profile, deletedAt: new Date() }));
    const result = await sut.execute(input);
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(InvalidAppleTokenError);
    expect(users.update).not.toHaveBeenCalled();
    expect(tokens.generate).not.toHaveBeenCalled();
  });

  it('rejects as a removed account if deletion wins credential rotation', async () => {
    users.findByAppleId.mockResolvedValue(right(profile));
    users.updateAppleCredential.mockResolvedValue(right(null));

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('INVALID_APPLE_TOKEN');
    expect(tokens.generate).not.toHaveBeenCalled();
  });
});
