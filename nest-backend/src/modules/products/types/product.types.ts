import { Prisma } from '@prisma/client';

export const PRODUCT_LIST_INCLUDE = {
  seller: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
  images: { orderBy: { order: 'asc' as const }, take: 1 },
} satisfies Prisma.ProductInclude;

export const PRODUCT_DETAIL_INCLUDE = {
  seller: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true, bio: true, city: true, state: true, createdAt: true } },
  category: true,
  images: { orderBy: { order: 'asc' as const } },
} satisfies Prisma.ProductInclude;

export type ProductListPayload = Prisma.ProductGetPayload<{ include: typeof PRODUCT_LIST_INCLUDE }>;
export type ProductDetailPayload = Prisma.ProductGetPayload<{ include: typeof PRODUCT_DETAIL_INCLUDE }>;

export interface FindManyParams {
  cursor?: string;
  limit?: number;
  search?: string;
  categoryId?: string;
  minPrice?: number;
  maxPrice?: number;
}
