export type ProductImage = { id?: string; url: string; order?: number; blurHash?: string | null };
export type ProductSeller = {
  id: string;
  displayName: string;
  avatarUrl?: string | null;
  avatarBlurHash?: string | null;
  isVerified?: boolean;
  bio?: string | null;
  city?: string | null;
  state?: string | null;
  createdAt?: string;
};
export type ProductSummary = {
  id: string;
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId: string;
  sellerId: string;
  status: 'ACTIVE' | 'PAUSED' | 'SOLD' | 'DELETED';
  quantity: number;
  soldCount: number;
  createdAt: string;
  seller: ProductSeller;
  images: ProductImage[];
};
export type ProductPage = { products: ProductSummary[]; nextCursor: string | null };
export type Category = { id: string; name: string; parentId: string | null; children: Category[] };
