export type TransactionEntry = {
  id: string;
  orderId: string;
  amount: number;
  status: string;
  createdAt: Date;
  type: 'PURCHASE' | 'SALE';
  productTitle: string | null;
};
