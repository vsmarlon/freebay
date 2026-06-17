import { isValidCpf, isValidCnpj, isValidCpfOrCnpj } from './cpf.utils';

describe('cpf.utils', () => {
  describe('isValidCpf', () => {
    it('accepts a valid formatted CPF', () => {
      expect(isValidCpf('529.982.247-25')).toBe(true);
    });

    it('accepts a valid unformatted CPF', () => {
      expect(isValidCpf('52998224725')).toBe(true);
    });

    it('rejects CPF with wrong length', () => {
      expect(isValidCpf('1234567890')).toBe(false);
    });

    it('rejects CPF with repeated digits', () => {
      expect(isValidCpf('111.111.111-11')).toBe(false);
    });

    it('rejects CPF with invalid check digits', () => {
      expect(isValidCpf('529.982.247-24')).toBe(false);
    });
  });

  describe('isValidCnpj', () => {
    it('accepts a valid formatted CNPJ', () => {
      expect(isValidCnpj('04.252.011/0001-10')).toBe(true);
    });

    it('accepts a valid unformatted CNPJ', () => {
      expect(isValidCnpj('04252011000110')).toBe(true);
    });

    it('rejects repeated digits', () => {
      expect(isValidCnpj('11.111.111/1111-11')).toBe(false);
    });

    it('rejects invalid verifier digits', () => {
      expect(isValidCnpj('04.252.011/0001-11')).toBe(false);
    });
  });

  describe('isValidCpfOrCnpj', () => {
    it('accepts valid CPF values', () => {
      expect(isValidCpfOrCnpj('529.982.247-25')).toBe(true);
    });

    it('accepts valid CNPJ values', () => {
      expect(isValidCpfOrCnpj('04.252.011/0001-10')).toBe(true);
    });

    it('rejects malformed values', () => {
      expect(isValidCpfOrCnpj('abc')).toBe(false);
      expect(isValidCpfOrCnpj('123')).toBe(false);
    });
  });
});
