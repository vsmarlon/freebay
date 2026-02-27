import { registerSchema, loginSchema } from './auth.dto';

describe('Auth DTOs', () => {
  describe('registerSchema', () => {
    it('should validate a correct register payload', () => {
      const result = registerSchema.safeParse({
        displayName: 'Test User',
        email: 'test@test.com',
        password: '12345678',
      });
      expect(result.success).toBe(true);
    });

    it('should reject invalid email', () => {
      const result = registerSchema.safeParse({
        displayName: 'Test User',
        email: 'not-an-email',
        password: '12345678',
      });
      expect(result.success).toBe(false);
    });

    it('should reject short password', () => {
      const result = registerSchema.safeParse({
        displayName: 'Test User',
        email: 'test@test.com',
        password: '123',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('loginSchema', () => {
    it('should validate a correct login payload', () => {
      const result = loginSchema.safeParse({
        email: 'test@test.com',
        password: '12345678',
      });
      expect(result.success).toBe(true);
    });

    it('should reject empty password', () => {
      const result = loginSchema.safeParse({
        email: 'test@test.com',
        password: '',
      });
      expect(result.success).toBe(false);
    });
  });
});
