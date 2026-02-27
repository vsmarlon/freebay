import { createCategorySchema } from './category.dto';

describe('Category DTOs', () => {
  describe('createCategorySchema', () => {
    it('should validate a correct payload without parentId', () => {
      const result = createCategorySchema.safeParse({
        name: 'Eletrônicos',
        slug: 'eletronicos',
      });
      expect(result.success).toBe(true);
    });

    it('should validate a correct payload with parentId', () => {
      const result = createCategorySchema.safeParse({
        name: 'Celulares',
        slug: 'celulares',
        parentId: '550e8400-e29b-41d4-a716-446655440000',
      });
      expect(result.success).toBe(true);
    });

    it('should reject short name', () => {
      const result = createCategorySchema.safeParse({
        name: 'A',
        slug: 'a-category',
      });
      expect(result.success).toBe(false);
    });

    it('should reject short slug', () => {
      const result = createCategorySchema.safeParse({
        name: 'Valid Name',
        slug: 'a',
      });
      expect(result.success).toBe(false);
    });

    it('should reject invalid parentId (non-uuid)', () => {
      const result = createCategorySchema.safeParse({
        name: 'Valid Name',
        slug: 'valid-slug',
        parentId: 'not-a-uuid',
      });
      expect(result.success).toBe(false);
    });

    it('should reject missing name', () => {
      const result = createCategorySchema.safeParse({
        slug: 'valid-slug',
      });
      expect(result.success).toBe(false);
    });
  });
});
