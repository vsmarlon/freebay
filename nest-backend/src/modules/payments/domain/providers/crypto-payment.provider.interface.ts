import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import {
  CryptoCurrency,
  EphemeralAddressPayload,
  CryptoDepositReceipt,
  CryptoPayoutResult,
  CryptoRefundResult,
} from '../../types/crypto-payment.types';

export abstract class CryptoPaymentProvider {
  abstract generateEphemeralAddress(
    orderId: string,
    currency: CryptoCurrency,
    amountInCents: number,
  ): Promise<Either<AppError, EphemeralAddressPayload>>;

  abstract checkDepositStatus(
    orderId: string,
    address: string,
    currency: CryptoCurrency,
  ): Promise<Either<AppError, CryptoDepositReceipt | null>>;

  abstract releaseEscrowPayout(
    orderId: string,
    sellerAddress: string,
    currency: CryptoCurrency,
    amountAtomic: string,
  ): Promise<Either<AppError, CryptoPayoutResult>>;

  abstract refundBuyer(
    orderId: string,
    buyerRefundAddress: string,
    currency: CryptoCurrency,
    amountAtomic: string,
  ): Promise<Either<AppError, CryptoRefundResult>>;
}
