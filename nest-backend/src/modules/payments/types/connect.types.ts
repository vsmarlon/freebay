export interface ConnectAccountSnapshot {
  stripeAccountId: string;
  country: string;
  defaultCurrency: string;
  transfersEnabled: boolean;
  payoutsEnabled: boolean;
  detailsSubmitted: boolean;
  requirementsDue: string[];
}

export interface CreateConnectAccountParams {
  email: string;
  displayName: string;
  country: string;
  currency: string;
}

export interface CreateTransferParams {
  amount: number;
  currency: string;
  destination: string;
  sourceTransaction: string;
  orderId: string;
}
