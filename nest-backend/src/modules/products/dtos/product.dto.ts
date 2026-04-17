import { z } from 'zod';

export const createProductSchema = z.object({
  title: z.string().min(3).max(100),
  description: z.string().min(10).max(5000),
  price: z.coerce.number().int().positive(),
  condition: z.enum(['NEW', 'USED']),
  categoryId: z.string().min(1),
  images: z.array(z.string()).max(10).optional().default([]),
});

export const productQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.string().optional(),
  search: z.string().optional(),
  category: z.string().optional(),
  minPrice: z.string().optional(),
  maxPrice: z.string().optional(),
});

export const updateProductSchema = z.object({
  title: z.string().min(3).max(100).optional(),
  description: z.string().min(10).max(5000).optional(),
  price: z.coerce.number().int().positive().optional(),
  condition: z.enum(['NEW', 'USED']).optional(),
  status: z.enum(['ACTIVE', 'PAUSED']).optional(),
  categoryId: z.string().min(1).optional(),
});

export type CreateProductDTO = z.infer<typeof createProductSchema>;
export type UpdateProductDTO = z.infer<typeof updateProductSchema>;

export interface CreateProductInput {
  sellerId: string;
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId: string;
  images: string[];
}

export interface CreateProductOutput {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId: string;
  sellerId: string;
  status: string;
  createdAt: Date;
}

export interface DeleteProductInput {
  productId: string;
  userId: string;
}

export interface UpdateProductInput {
  productId: string;
  userId: string;
  title?: string;
  description?: string;
  price?: number;
  condition?: 'NEW' | 'USED';
  status?: 'ACTIVE' | 'PAUSED';
  categoryId?: string;
}

export interface UpdateProductOutput {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId: string;
  sellerId: string;
  status: string;
  createdAt: Date;
 }

export interface DeleteProductOutput {
  deleted: boolean;
}
