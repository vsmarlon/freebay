import { createProductSchema } from './product.dto';

describe('Product DTOs', () => {
  describe('createProductSchema', () => {
    it('should validate a correct payload', () => {
      const result = createProductSchema.safeParse({
        title: 'iPhone 15',
        description: 'Brand new iPhone 15, sealed in box',
        price: 500000,
        condition: 'NEW',
      });
      expect(result.success).toBe(true);
    });

    it('should reject short title', () => {
      const result = createProductSchema.safeParse({
        title: 'ab',
        description: 'A valid description here',
        price: 5000,
        condition: 'NEW',
      });
      expect(result.success).toBe(false);
    });

    it('should reject short description', () => {
      const result = createProductSchema.safeParse({
        title: 'Valid Title',
        description: 'Too short',
        price: 5000,
        condition: 'NEW',
      });
      expect(result.success).toBe(false);
    });

    it('should reject negative price', () => {
      const result = createProductSchema.safeParse({
        title: 'Valid Title',
        description: 'A valid description text',
        price: -100,
        condition: 'NEW',
      });
      expect(result.success).toBe(false);
    });

    it('should reject decimal price', () => {
      const result = createProductSchema.safeParse({
        title: 'Valid Title',
        description: 'A valid description text',
        price: 99.99,
        condition: 'NEW',
      });
      expect(result.success).toBe(false);
    });

    it('should reject invalid condition', () => {
      const result = createProductSchema.safeParse({
        title: 'Valid Title',
        description: 'A valid description text',
        price: 5000,
        condition: 'REFURBISHED',
      });
      expect(result.success).toBe(false);
    });

    it('should accept USED condition', () => {
      const result = createProductSchema.safeParse({
        title: 'Used Phone',
        description: 'Good condition used phone',
        price: 30000,
        condition: 'USED',
      });
      expect(result.success).toBe(true);
    });
  });
});
