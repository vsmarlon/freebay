import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { MoneroRpcProvider } from './monero-rpc.provider';
import { CryptoCurrency } from '../types/crypto-payment.types';

describe('MoneroRpcProvider', () => {
  let provider: MoneroRpcProvider;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MoneroRpcProvider,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string, defaultValue: string) => defaultValue),
          },
        },
      ],
    }).compile();

    provider = module.get<MoneroRpcProvider>(MoneroRpcProvider);
  });

  it('should generate an ephemeral Monero subaddress for an order', async () => {
    const result = await provider.generateEphemeralAddress('order-123', CryptoCurrency.XMR, 5000);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.orderId).toBe('order-123');
      expect(result.value.currency).toBe(CryptoCurrency.XMR);
      expect(result.value.address).toMatch(/^8/);
      expect(result.value.uriQrCode).toContain('monero:8');
      expect(result.value.expiresAt.getTime()).toBeGreaterThan(Date.now());
    }
  });

  it('should return error when currency is not XMR', async () => {
    const result = await provider.generateEphemeralAddress('order-123', CryptoCurrency.USDT_POLYGON, 5000);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value.code).toBe('UNSUPPORTED_CURRENCY');
    }
  });

  it('should verify deposit confirmation status', async () => {
    const result = await provider.checkDepositStatus('order-123', '8mockaddress', CryptoCurrency.XMR);

    expect(result.isRight()).toBe(true);
    if (result.isRight() && result.value) {
      expect(result.value.orderId).toBe('order-123');
      expect(result.value.isConfirmed).toBe(true);
      expect(result.value.confirmations).toBeGreaterThanOrEqual(10);
    }
  });

  it('should release escrow payout to seller address', async () => {
    const result = await provider.releaseEscrowPayout('order-123', '8selleraddress', CryptoCurrency.XMR, '500000000000');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.recipientAddress).toBe('8selleraddress');
      expect(result.value.payoutTxHash).toBeDefined();
    }
  });

  it('should refund buyer Monero payment', async () => {
    const result = await provider.refundBuyer('order-123', '8buyeraddress', CryptoCurrency.XMR, '500000000000');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.refundAddress).toBe('8buyeraddress');
      expect(result.value.refundTxHash).toBeDefined();
    }
  });
});
