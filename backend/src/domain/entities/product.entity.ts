export interface ProductEntity {
  id: string;
  title: string;
  description: string;
  price: number; // centavos
  condition: 'NEW' | 'USED';
  categoryId: string | null;
  status: 'ACTIVE' | 'SOLD' | 'PAUSED' | 'DELETED';
  sellerId: string;
  postId: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}

export interface ProductImageEntity {
  id: string;
  url: string;
  order: number;
  productId: string;
}
