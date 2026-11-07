import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';
import { JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { JwtTokenValidatorService } from './jwt-token-validator.service';
import { UserRole } from '@prisma/client';
import { SessionRevokerService } from './session-revoker.service';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';

describe('JwtTokenValidatorService session revocation', () => {
  const invalidBefore = 1_700_000_000_500;

  async function createValidator(payload: object, familyRevoked = false, durableCutoff: Date | null = null, cachedCutoff: string | null = String(invalidBefore)) {
    const jwt = { verifyAsync: jest.fn().mockResolvedValue(payload) };
    const config = { getOrThrow: jest.fn().mockReturnValue('secret') };
    const redis = { exists: jest.fn().mockResolvedValue(familyRevoked), get: jest.fn().mockResolvedValue(cachedCutoff) };
    const module = await Test.createTestingModule({
      providers: [
        JwtTokenValidatorService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: config },
        { provide: RedisService, useValue: redis },
        { provide: SessionRevokerService, useValue: { revokeFamily: jest.fn() } },
        { provide: AuthSessionStateDatabaseRepository, useValue: { findInvalidBefore: jest.fn().mockResolvedValue(durableCutoff) } },
      ],
    }).compile();
    return module.get(JwtTokenValidatorService);
  }

  it('rejects a token issued immediately before revoke in the same second', async () => {
    const validator = await createValidator({ userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS, iat: 1_700_000_000, issuedAtMs: invalidBefore - 1 });

    await expect(validator.verifyAndValidate('token')).rejects.toThrow(new UnauthorizedException('Sessão expirada'));
  });

  it('accepts a token issued after revoke in the same second', async () => {
    const validator = await createValidator({ userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS, iat: 1_700_000_000, issuedAtMs: invalidBefore + 1 });

    await expect(validator.verifyAndValidate('token')).resolves.toEqual(expect.objectContaining({
      issuedAtMs: invalidBefore + 1,
      sessionStartedAtMs: invalidBefore + 1,
    }));
  });

  it('rejects a token at the durable cutoff when Redis has no revocation marker', async () => {
    const validator = await createValidator(
      { userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS, iat: 1_700_000_000, issuedAtMs: invalidBefore },
      false,
      new Date(invalidBefore),
    );

    await expect(validator.verifyAndValidate('token')).rejects.toThrow(new UnauthorizedException('Sessão expirada'));
  });

  it('uses the signed session origin instead of the later token mint timestamp', async () => {
    const validator = await createValidator({
      userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS,
      issuedAtMs: invalidBefore + 1_000, sessionStartedAtMs: invalidBefore,
    });

    await expect(validator.verifyAndValidate('token')).rejects.toThrow('Sessão expirada');
  });

  it('fails closed for a malformed present origin and accepts timestamp zero as a valid legacy origin', async () => {
    const malformed = await createValidator({
      userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS,
      iat: 1_700_000_001, issuedAtMs: invalidBefore + 1, sessionStartedAtMs: Number.NaN,
    });
    await expect(malformed.verifyAndValidate('token')).rejects.toThrow('Token sem origem de sessão válida');

    const zeroOrigin = await createValidator({
      userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS, sessionStartedAtMs: 0,
    }, false, null, null);
    await expect(zeroOrigin.verifyAndValidate('token')).resolves.toHaveProperty('sessionStartedAtMs', 0);
  });

  it('fails closed when every signed session-origin timestamp is absent', async () => {
    const validator = await createValidator({ userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS }, false, null, null);
    await expect(validator.verifyAndValidate('token')).rejects.toThrow('Token sem origem de sessão válida');
  });

  it('keeps legacy second-resolution tokens on their existing safe semantics', async () => {
    const validator = await createValidator({ userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS, iat: 1_699_999_999 });

    await expect(validator.verifyAndValidate('token')).rejects.toThrow('Sessão expirada');
  });

  it.each([JwtTokenType.ACCESS, JwtTokenType.BIOMETRIC, JwtTokenType.REFRESH])(
    'rejects %s tokens from a revoked refresh-token family',
    async (type) => {
      const validator = await createValidator({
        userId: 'user-1', role: UserRole.USER, type, sid: 'family-1', iat: 1_700_000_001,
      }, true);

      await expect(validator.verifyAndValidate('token', [type])).rejects.toThrow(
        new UnauthorizedException('Família de sessão revogada'),
      );
    },
  );
});
