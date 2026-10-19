import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, createHmac, randomBytes } from 'node:crypto';
import { isValidCpfOrCnpj } from './cpf.utils';

const VERSION = 'v1';

@Injectable()
export class CpfProtectionService {
  constructor(private readonly config: ConfigService) {}

  normalize(value: string): string {
    const normalized = value.replace(/[.\-/]/g, '').toUpperCase();
    if (!/^(\d{11}|[A-Z0-9]{14})$/.test(normalized)) throw new Error('CPF/CNPJ inválido');
    if (!isValidCpfOrCnpj(normalized)) throw new Error('CPF/CNPJ inválido');
    return normalized;
  }

  protect(value: string): { cpf: string; cpfHash: string } {
    const normalized = this.normalize(value);
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.key('CPF_ENCRYPTION_KEY'), iv);
    const ciphertext = Buffer.concat([cipher.update(normalized, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    const hash = createHmac('sha256', this.key('CPF_HMAC_KEY')).update(normalized, 'utf8').digest('hex');
    return {
      cpf: `${VERSION}:${iv.toString('base64url')}:${tag.toString('base64url')}:${ciphertext.toString('base64url')}`,
      cpfHash: `${VERSION}:${hash}`,
    };
  }

  decrypt(value: string | null | undefined): string | null {
    if (!value || !value.startsWith(`${VERSION}:`)) return null;
    const [, encodedIv, encodedTag, encodedCiphertext, extra] = value.split(':');
    if (!encodedIv || !encodedTag || !encodedCiphertext || extra !== undefined) throw new Error('Invalid encrypted CPF format');
    const decipher = createDecipheriv('aes-256-gcm', this.key('CPF_ENCRYPTION_KEY'), Buffer.from(encodedIv, 'base64url'));
    decipher.setAuthTag(Buffer.from(encodedTag, 'base64url'));
    const plaintext = Buffer.concat([
      decipher.update(Buffer.from(encodedCiphertext, 'base64url')),
      decipher.final(),
    ]).toString('utf8');
    return this.normalize(plaintext);
  }

  private key(name: 'CPF_ENCRYPTION_KEY' | 'CPF_HMAC_KEY'): Buffer {
    const encoded = this.config.get<string>(name);
    if (!encoded || !/^[A-Za-z0-9+/]+={0,2}$/.test(encoded)) throw new Error(`${name} must be a base64-encoded 32-byte key`);
    const key = Buffer.from(encoded, 'base64');
    if (key.length !== 32 || key.toString('base64') !== encoded) throw new Error(`${name} must be a base64-encoded 32-byte key`);
    return key;
  }
}
