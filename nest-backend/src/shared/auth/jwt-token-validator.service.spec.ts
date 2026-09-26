import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';
import { JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { JwtTokenValidatorService } from './jwt-token-validator.service';
import { UserRole } from '@prisma/client';

describe('JwtTokenValidatorService session revocation', () => {
  const invalidBefore = 1_700_000_000_500;

  async function createValidator(payload: object) {
    const jwt = { verifyAsync: jest.fn().mockResolvedValue(payload) };
    const config = { getOrThrow: jest.fn().mockReturnValue('secret') };
    const redis = { exists: jest.fn().mockResolvedValue(false), get: jest.fn().mockResolvedValue(String(invalidBefore)) };
    const module = await Test.createTestingModule({
      providers: [
        JwtTokenValidatorService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: config },
        { provide: RedisService, useValue: redis },
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

    await expect(validator.verifyAndValidate('token')).resolves.toEqual(expect.objectContaining({ issuedAtMs: invalidBefore + 1 }));
  });

  it('keeps legacy second-resolution tokens on their existing safe semantics', async () => {
    const validator = await createValidator({ userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS, iat: 1_699_999_999 });

    await expect(validator.verifyAndValidate('token')).rejects.toThrow('Sessão expirada');
  });
});
