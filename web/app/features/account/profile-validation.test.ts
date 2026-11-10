import { describe, expect, it } from 'vitest';
import { formatPhone, maskCpf, validCpfOrCnpj, validPhone } from './profile-validation';

describe('account profile validation', () => {
  it('accepts only valid CPF/CNPJ check digits and preserves masks', () => {
    expect(validCpfOrCnpj('529.982.247-25')).toBe(true);
    expect(validCpfOrCnpj('11.222.333/0001-81')).toBe(true);
    expect(validCpfOrCnpj('529.982.247-24')).toBe(false);
    expect(validCpfOrCnpj('111.111.111-11')).toBe(false);
    expect(maskCpf('52998224725')).toBe('529.***.***-25');
    expect(maskCpf('11222333000181')).toBe('11.***.***/****-81');
  });

  it('formats and validates Brazilian phone number lengths', () => {
    expect(formatPhone('11987654321')).toBe('(11) 98765-4321');
    expect(formatPhone('1133334444')).toBe('(11) 3333-4444');
    expect(validPhone('(11) 98765-4321')).toBe(true);
    expect(validPhone('119876543')).toBe(false);
  });
});
