import { z } from 'zod';

export const createCategorySchema = z.object({
  name: z.string().min(2).max(100),
  slug: z.string().min(2).max(100),
  parentId: z.string().uuid().optional(),
});

export type CreateCategoryDTO = z.infer<typeof createCategorySchema>;
