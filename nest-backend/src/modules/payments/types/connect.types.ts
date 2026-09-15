export type ConnectStatus =
  | 'onboarding-required'
  | 'requirements-due'
  | 'restricted'
  | 'transfer-ready';

export interface ConnectAccountSnapshot {
  stripeAccountId: string;
  country: string;
  defaultCurrency: string;
  status: ConnectStatus;
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
  transactionId: string;
  paymentGroupId?: string;
  transferGroup: string;
  idempotencyKey: string;
}

export interface TransferReconciliationParams {
  transferId?: string;
  transferGroup: string;
  orderId: string;
  transactionId: string;
  paymentGroupId?: string;
  destination: string;
  idempotencyKey: string;
}

export interface TransferReconciliationResult {
  providerId: string;
  reversalId?: string;
}

export interface ReversalReconciliationParams {
  transferId: string;
  reversalId?: string;
  orderId: string;
  transactionId: string;
  idempotencyKey: string;
}
