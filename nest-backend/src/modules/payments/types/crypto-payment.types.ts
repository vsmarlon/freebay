export enum CryptoCurrency {
  XMR = 'XMR',
  USDT_POLYGON = 'USDT_POLYGON',
  USDT_TRC20 = 'USDT_TRC20',
  USDC_SOLANA = 'USDC_SOLANA',
}

export enum CryptoEscrowStatus {
  PENDING_DEPOSIT = 'PENDING_DEPOSIT',
  DETECTED_UNCONFIRMED = 'DETECTED_UNCONFIRMED',
  HELD_IN_ESCROW = 'HELD_IN_ESCROW',
  RELEASED_TO_SELLER = 'RELEASED_TO_SELLER',
  REFUNDED_TO_BUYER = 'REFUNDED_TO_BUYER',
  EXPIRED = 'EXPIRED',
}

export interface EphemeralAddressPayload {
  orderId: string;
  currency: CryptoCurrency;
  address: string;
  paymentId?: string;
  uriQrCode: string;
  amountAtomic: string;
  amountHuman: string;
  expiresAt: Date;
}

export interface CryptoDepositReceipt {
  txHash: string;
  orderId: string;
  currency: CryptoCurrency;
  amountAtomic: string;
  confirmations: number;
  isConfirmed: boolean;
  detectedAt: Date;
}

export interface CryptoPayoutResult {
  payoutTxHash: string;
  recipientAddress: string;
  currency: CryptoCurrency;
  amountAtomic: string;
  feeAtomic: string;
  timestamp: Date;
}

export interface CryptoRefundResult {
  refundTxHash: string;
  refundAddress: string;
  currency: CryptoCurrency;
  amountAtomic: string;
  timestamp: Date;
}
