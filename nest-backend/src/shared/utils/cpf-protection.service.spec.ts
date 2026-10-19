import { ConfigService } from '@nestjs/config';
import { CpfProtectionService } from './cpf-protection.service';

describe('CpfProtectionService', () => {
  const config = new ConfigService({
    CPF_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
    CPF_HMAC_KEY: Buffer.alloc(32, 2).toString('base64'),
  });
  const service = new CpfProtectionService(config);

  it('encrypts, authenticates and deterministically hashes normalized identifiers', () => {
    const first = service.protect('529.982.247-25');
    const second = service.protect('52998224725');

    expect(first.cpf).not.toContain('52998224725');
    expect(first.cpf).not.toBe(second.cpf);
    expect(first.cpfHash).toBe(second.cpfHash);
    expect(service.decrypt(first.cpf)).toBe('52998224725');
    expect(service.decrypt('52998224725')).toBeNull();
    expect(service.protect('12.ABC.345/01DE-35').cpfHash).toMatch(/^v1:[0-9a-f]{64}$/);
  });

  it('rejects CPF input with extra alphanumeric data even when its digits form a valid CPF', () => {
    expect(() => service.protect('529.982.247-25x')).toThrow('CPF/CNPJ inválido');
  });

  it('fails closed when a key is missing or ciphertext is tampered', () => {
    const encrypted = service.protect('52998224725').cpf;
    const processHmacKey = process.env.CPF_HMAC_KEY;
    delete process.env.CPF_HMAC_KEY;
    try {
      const missingKey = new CpfProtectionService(new ConfigService({
        CPF_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
      }));
      expect(() => missingKey.protect('52998224725')).toThrow('CPF_HMAC_KEY');
    } finally {
      if (processHmacKey === undefined) delete process.env.CPF_HMAC_KEY;
      else process.env.CPF_HMAC_KEY = processHmacKey;
    }
    expect(() => service.decrypt(`${encrypted.slice(0, -1)}A`)).toThrow();
  });
});
