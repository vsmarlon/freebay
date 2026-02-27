import { createCommentSchema } from './social.dto';

describe('Social DTOs', () => {
  describe('createCommentSchema', () => {
    it('should validate a correct payload', () => {
      const result = createCommentSchema.safeParse({ content: 'Great post!' });
      expect(result.success).toBe(true);
    });

    it('should reject empty content', () => {
      const result = createCommentSchema.safeParse({ content: '' });
      expect(result.success).toBe(false);
    });

    it('should reject content over 500 chars', () => {
      const result = createCommentSchema.safeParse({ content: 'a'.repeat(501) });
      expect(result.success).toBe(false);
    });

    it('should accept content at exactly 500 chars', () => {
      const result = createCommentSchema.safeParse({ content: 'a'.repeat(500) });
      expect(result.success).toBe(true);
    });

    it('should reject missing content', () => {
      const result = createCommentSchema.safeParse({});
      expect(result.success).toBe(false);
    });
  });
});
