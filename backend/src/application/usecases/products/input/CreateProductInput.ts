export interface CreateProductInput {
  title: string;
  description: string;
  price: number;
  condition: 'NEW' | 'USED';
  categoryId?: string;
  sellerId: string;
}
