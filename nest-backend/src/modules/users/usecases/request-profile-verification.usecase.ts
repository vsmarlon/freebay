import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomInt, createHmac } from 'crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { ResendService } from '@/modules/auth/services/resend.service';
import { isValidCpfOrCnpj } from '@/shared/utils/cpf.utils';

const TTL = 600;
const COOLDOWN = 60;
const MAX_REQUESTS = 10;
const CHALLENGE_KEY = (id: string) => `profile-verification:cpf:${id}`;
const ATTEMPTS_KEY = (id: string) => `profile-verification:cpf:attempts:${id}`;
const REQUEST_KEY = (id: string) => `profile-verification:cpf:request:${id}`;
const WINDOW_KEY = (id: string) => `profile-verification:cpf:window:${id}`;

const CONSUME_SCRIPT = `
local stored = redis.call('GET', KEYS[1])
if not stored then return 0 end
if stored ~= ARGV[1] then
  local attempts = redis.call('INCR', KEYS[2])
  if attempts == 1 then redis.call('EXPIRE', KEYS[2], ARGV[2]) end
  if attempts >= 5 then redis.call('DEL', KEYS[1], KEYS[2]) end
  return attempts >= 5 and 3 or 2
end
redis.call('DEL', KEYS[1], KEYS[2])
return 1
`;

@Injectable()
export class RequestProfileVerificationUseCase {
  constructor(
    private readonly users: UserDatabaseRepository,
    private readonly redis: RedisService,
    private readonly resend: ResendService,
    private readonly config: ConfigService,
  ) {}

  async request(input: { userId: string; cpf: string; locale: 'pt-BR' | 'en' }): Promise<Either<AppError, { expiresIn: number; resendAfter: number }>> {
    const normalizedCpf = input.cpf.replace(/\D/g, '');
    if (!isValidCpfOrCnpj(normalizedCpf)) return left(new AppError('INVALID_PROFILE_VERIFICATION', 'Documento inv\u00e1lido', 400));
    const userResult = await this.users.findById(input.userId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) return left(new NotFoundError('User'));

    const secret = this.config.getOrThrow<string>('JWT_SECRET');
    const challengeKey = CHALLENGE_KEY(input.userId);
    const rateWindowKey = WINDOW_KEY(input.userId);
    const [hasCooldown, count] = await Promise.all([
      this.redis.setIfAbsent(REQUEST_KEY(input.userId), '1', COOLDOWN).then((ok) => !ok),
      this.redis.incrementWithExpiry(rateWindowKey, 3600),
    ]);
    if (hasCooldown || count > MAX_REQUESTS) return left(new AppError('PROFILE_VERIFICATION_RATE_LIMITED', 'Aguarde antes de solicitar outro c\u00f3digo', 429));
    await this.redis.del(challengeKey);
    await this.redis.del(ATTEMPTS_KEY(input.userId));

    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    const digest = this.digest(secret, input.userId, userResult.value.email, normalizedCpf, code);
    try {
      const sent = await this.resend.sendProfileVerificationCode(userResult.value.email, code, input.locale);
      if (!sent) return left(new AppError('PROFILE_VERIFICATION_DELIVERY_FAILED', 'N\u00e3o foi poss\u00edvel enviar o c\u00f3digo', 503));
      await this.redis.add(challengeKey, digest, TTL);
    } catch {
      return left(new AppError('PROFILE_VERIFICATION_UNAVAILABLE', 'Verifica\u00e7\u00e3o temporariamente indispon\u00edvel', 503));
    }
    return right({ expiresIn: TTL, resendAfter: COOLDOWN });
  }

  async consume(input: { userId: string; cpf: string; code: string }): Promise<Either<AppError, void>> {
    const userResult = await this.users.findById(input.userId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) return left(new NotFoundError('User'));
    const stored = await this.redis.get(CHALLENGE_KEY(input.userId));
    if (!stored) {
      return input.code
        ? left(new AppError('PROFILE_VERIFICATION_EXPIRED', 'C\u00f3digo inv\u00e1lido ou expirado', 410))
        : left(new AppError('PROFILE_VERIFICATION_REQUIRED', 'Verifique seu e-mail antes de alterar o documento', 403));
    }
    const normalizedCpf = input.cpf.replace(/\D/g, '');
    const expected = this.digest(this.config.getOrThrow<string>('JWT_SECRET'), input.userId, userResult.value.email, normalizedCpf, input.code);
    const result = await this.redis.eval(CONSUME_SCRIPT, [CHALLENGE_KEY(input.userId), ATTEMPTS_KEY(input.userId)], [expected, String(TTL)]);
    if (result === 1) return right(undefined);
    if (result === 3) return left(new AppError('PROFILE_VERIFICATION_ATTEMPTS_EXCEEDED', 'Limite de tentativas excedido', 429));
    if (result === 0) return left(new AppError('PROFILE_VERIFICATION_EXPIRED', 'C\u00f3digo inv\u00e1lido ou expirado', 410));
    return left(new AppError('PROFILE_VERIFICATION_INVALID', 'C\u00f3digo inv\u00e1lido ou expirado', 400));
  }

  private digest(secret: string, userId: string, email: string, cpf: string, code: string): string {
    return createHmac('sha256', secret).update(`profile-cpf-v1\0${userId}\0${email}\0${cpf}\0${code}`).digest('hex');
  }
}
