import { withdrawSchema } from './wallet.dto';

describe('Wallet DTOs', () => {
  describe('withdrawSchema', () => {
    it('should validate a correct payload', () => {
      const result = withdrawSchema.safeParse({ amount: 5000 });
      expect(result.success).toBe(true);
    });

    it('should reject zero amount', () => {
      const result = withdrawSchema.safeParse({ amount: 0 });
      expect(result.success).toBe(false);
    });

    it('should reject negative amount', () => {
      const result = withdrawSchema.safeParse({ amount: -100 });
      expect(result.success).toBe(false);
    });

    it('should reject missing amount', () => {
      const result = withdrawSchema.safeParse({});
      expect(result.success).toBe(false);
    });

    it('should accept decimal amount', () => {
      const result = withdrawSchema.safeParse({ amount: 99.5 });
      expect(result.success).toBe(true);
    });
  });
});
