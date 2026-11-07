export enum ConnectStatus {
  ONBOARDING_REQUIRED = 'onboarding-required',
  REQUIREMENTS_DUE = 'requirements-due',
  RESTRICTED = 'restricted',
  TRANSFER_READY = 'transfer-ready',
}

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
