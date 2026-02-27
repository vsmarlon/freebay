export interface ReviewEntity {
  id: string;
  reviewerId: string;
  reviewedId: string;
  orderId: string;
  type: 'BUYER_REVIEWING_SELLER' | 'SELLER_REVIEWING_BUYER';
  score: number;
  comment: string | null;
  createdAt: Date;
}
