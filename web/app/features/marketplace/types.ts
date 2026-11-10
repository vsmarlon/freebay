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
  pauseReason?: 'SELLER' | 'RESERVED' | 'MODERATION' | null;
  quantity: number;
  soldCount: number;
  createdAt: string;
  seller: ProductSeller;
  images: ProductImage[];
};
export type ProductPage = { products: ProductSummary[]; nextCursor: string | null };
export type Category = { id: string; name: string; parentId: string | null; children: Category[] };
// ponytail: the backend ships product imagery as `media[]` while the web contract (and fixtures) use `images[]`; normalize at fetch boundaries.
type ProductRaw = Omit<ProductSummary, 'images'> & { images?: unknown; media?: unknown };
const isImage = (value: unknown): value is ProductImage =>
  Boolean(value && typeof value === 'object' && typeof (value as ProductImage).url === 'string');
export function toProductSummary(raw: ProductRaw): ProductSummary {
  const { images, media, ...product } = raw;
  const source = images ?? media;
  return { ...product, images: (Array.isArray(source) ? source : []).filter(isImage) };
}
