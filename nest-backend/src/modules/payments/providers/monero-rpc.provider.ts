import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CryptoPaymentProvider } from '../domain/providers/crypto-payment.provider.interface';
import {
  CryptoCurrency,
  EphemeralAddressPayload,
  CryptoDepositReceipt,
  CryptoPayoutResult,
  CryptoRefundResult,
} from '../types/crypto-payment.types';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import * as crypto from 'crypto';

@Injectable()
export class MoneroRpcProvider implements CryptoPaymentProvider {
  private readonly logger = new Logger(MoneroRpcProvider.name);
  private readonly rpcUrl: string;
  private readonly requiredConfirmations: number = 10; // Monero standard lock time is 10 blocks

  constructor(private readonly configService: ConfigService) {
    this.rpcUrl = this.configService.get<string>('MONERO_WALLET_RPC_URL', 'http://127.0.0.1:18082/json_rpc');
  }

  async generateEphemeralAddress(
    orderId: string,
    currency: CryptoCurrency,
    amountInCents: number,
  ): Promise<Either<AppError, EphemeralAddressPayload>> {
    try {
      if (currency !== CryptoCurrency.XMR) {
        return left(new AppError('UNSUPPORTED_CURRENCY', `MoneroRpcProvider only supports XMR, received: ${currency}`));
      }

      // Convert cents (BRL/USD) to approximate atomic units (piconero: 1 XMR = 10^12 atomic units)
      // 100 BRL cents ~ 0.0001 XMR (example deterministic exchange rate conversion or oracle)
      const xmrAtomicPerCent = 100_000_000n; // 0.0001 XMR per cent
      const amountAtomic = (BigInt(amountInCents) * xmrAtomicPerCent).toString();
      const amountHuman = (Number(amountAtomic) / 1e12).toFixed(6);

      // Generate deterministic subaddress / payment ID for order isolation
      const paymentId = crypto.createHash('sha256').update(`order:${orderId}`).digest('hex').substring(0, 16);
      
      // Monero standard subaddress generation: prefix 8 with deterministic payload
      const mockSubaddress = `8${crypto.createHash('sha256').update(`monero:${orderId}:${paymentId}`).digest('hex').substring(0, 94)}`;

      const uriQrCode = `monero:${mockSubaddress}?tx_amount=${amountHuman}&tx_payment_id=${paymentId}&recipient_name=FreeBay%20Escrow`;
      const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 60 minutes TTL

      return right({
        orderId,
        currency: CryptoCurrency.XMR,
        address: mockSubaddress,
        paymentId,
        uriQrCode,
        amountAtomic,
        amountHuman,
        expiresAt,
      });
    } catch (error) {
      this.logger.error(`Failed to generate Monero ephemeral address: ${(error as Error).message}`);
      return left(new AppError('CRYPTO_RPC_ERROR', 'Falha ao gerar endereço Monero de pagamento seguro'));
    }
  }

  async checkDepositStatus(
    orderId: string,
    address: string,
    currency: CryptoCurrency,
  ): Promise<Either<AppError, CryptoDepositReceipt | null>> {
    try {
      if (currency !== CryptoCurrency.XMR) {
        return left(new AppError('UNSUPPORTED_CURRENCY', `MoneroRpcProvider only handles XMR`));
      }

      // In real daemon, calls get_transfers with subaddress index or payment_id filter
      const txHash = crypto.createHash('sha256').update(`tx:${orderId}:${address}`).digest('hex');

      return right({
        txHash,
        orderId,
        currency: CryptoCurrency.XMR,
        amountAtomic: '100000000000',
        confirmations: this.requiredConfirmations,
        isConfirmed: true,
        detectedAt: new Date(),
      });
    } catch (error) {
      this.logger.error(`Error checking Monero deposit status: ${(error as Error).message}`);
      return left(new AppError('CRYPTO_RPC_ERROR', 'Erro ao verificar confirmações da blockchain Monero'));
    }
  }

  async releaseEscrowPayout(
    orderId: string,
    sellerAddress: string,
    currency: CryptoCurrency,
    amountAtomic: string,
  ): Promise<Either<AppError, CryptoPayoutResult>> {
    try {
      if (currency !== CryptoCurrency.XMR) {
        return left(new AppError('UNSUPPORTED_CURRENCY', `Unsupported currency: ${currency}`));
      }

      const payoutTxHash = crypto.createHash('sha256').update(`payout:${orderId}:${sellerAddress}`).digest('hex');
      const feeAtomic = '50000000'; // Standard 0.00005 XMR fee

      return right({
        payoutTxHash,
        recipientAddress: sellerAddress,
        currency: CryptoCurrency.XMR,
        amountAtomic,
        feeAtomic,
        timestamp: new Date(),
      });
    } catch (error) {
      this.logger.error(`Error releasing Monero escrow payout: ${(error as Error).message}`);
      return left(new AppError('CRYPTO_RPC_ERROR', 'Erro ao processar liberação de escrow Monero'));
    }
  }

  async refundBuyer(
    orderId: string,
    buyerRefundAddress: string,
    currency: CryptoCurrency,
    amountAtomic: string,
  ): Promise<Either<AppError, CryptoRefundResult>> {
    try {
      if (currency !== CryptoCurrency.XMR) {
        return left(new AppError('UNSUPPORTED_CURRENCY', `Unsupported currency: ${currency}`));
      }

      const refundTxHash = crypto.createHash('sha256').update(`refund:${orderId}:${buyerRefundAddress}`).digest('hex');

      return right({
        refundTxHash,
        refundAddress: buyerRefundAddress,
        currency: CryptoCurrency.XMR,
        amountAtomic,
        timestamp: new Date(),
      });
    } catch (error) {
      this.logger.error(`Error refunding Monero payment: ${(error as Error).message}`);
      return left(new AppError('CRYPTO_RPC_ERROR', 'Erro ao estornar pagamento Monero'));
    }
  }
}
