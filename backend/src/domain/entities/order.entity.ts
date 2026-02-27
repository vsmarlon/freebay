export interface OrderEntity {
  id: string;
  buyerId: string;
  sellerId: string;
  productId: string;
  amount: number; // centavos
  platformFee: number;
  sellerAmount: number;
  status: 'PENDING' | 'CONFIRMED' | 'DISPUTED' | 'COMPLETED' | 'CANCELLED';
  escrowStatus: 'HELD' | 'RELEASED' | 'REFUNDED';
  meetingScheduledAt: Date | null;
  deliveryConfirmedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}
