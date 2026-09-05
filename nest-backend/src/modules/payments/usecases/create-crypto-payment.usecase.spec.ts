import { CreateCryptoPaymentUseCase } from './create-crypto-payment.usecase';
import { CryptoPaymentProvider } from '../domain/providers/crypto-payment.provider.interface';
import { CryptoCurrency } from '../types/crypto-payment.types';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { right, left } from '@/shared/core/either';
import { NotFoundError, BadRequestError, CryptoRpcError } from '@/shared/core/errors';

describe('CreateCryptoPaymentUseCase', () => {
  let sut: CreateCryptoPaymentUseCase;
  let orderRepository: jest.Mocked<Partial<OrderRepository>>;
  let cryptoPaymentProvider: jest.Mocked<Partial<CryptoPaymentProvider>>;

  const mockOrder = {
    id: 'order-1',
    buyerId: 'user-1',
    sellerId: 'user-2',
    productId: 'prod-1',
    amount: 1990,
    platformFee: 0,
    sellerAmount: 1990,
    status: 'PENDING',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockPayload = {
    orderId: 'order-1',
    currency: CryptoCurrency.XMR,
    address: '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3Gfn...',
    paymentId: 'a1b2c3d4e5f60718',
    uriQrCode: 'monero:888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3Gfn...?tx_amount=0.019900&tx_payment_id=a1b2c3d4e5f60718',
    amountAtomic: '199000000000',
    amountHuman: '0.019900',
    expiresAt: new Date(Date.now() + 3600000),
  };

  beforeEach(() => {
    orderRepository = {
      findById: jest.fn().mockResolvedValue(right(mockOrder)),
    };
    cryptoPaymentProvider = {
      generateEphemeralAddress: jest.fn().mockResolvedValue(right(mockPayload)),
    };

    sut = new CreateCryptoPaymentUseCase(
      orderRepository as OrderRepository,
      cryptoPaymentProvider as CryptoPaymentProvider,
    );
  });

  it('should generate an ephemeral Monero address for a valid pending order', async () => {
    const result = await sut.execute({
      orderId: 'order-1',
      userId: 'user-1',
      currency: 'XMR',
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.address).toBe(mockPayload.address);
      expect(result.value.uriQrCode).toContain('monero:888');
      expect(result.value.currency).toBe(CryptoCurrency.XMR);
    }
    expect(cryptoPaymentProvider.generateEphemeralAddress).toHaveBeenCalledWith(
      'order-1',
      CryptoCurrency.XMR,
      1990,
    );
  });

  it('should return NotFoundError if order does not exist', async () => {
    orderRepository.findById = jest.fn().mockResolvedValue(right(null));

    const result = await sut.execute({
      orderId: 'non-existent',
      userId: 'user-1',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('should return BadRequestError if user is not the buyer', async () => {
    const result = await sut.execute({
      orderId: 'order-1',
      userId: 'other-user',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
    }
  });

  it('should return BadRequestError if order is not pending', async () => {
    orderRepository.findById = jest.fn().mockResolvedValue(
      right({ ...mockOrder, status: 'CONFIRMED' }),
    );

    const result = await sut.execute({
      orderId: 'order-1',
      userId: 'user-1',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
    }
  });

  it('should return AppError if provider fails', async () => {
    cryptoPaymentProvider.generateEphemeralAddress = jest.fn().mockResolvedValue(
      left(new CryptoRpcError('Wallet RPC offline', 503)),
    );

    const result = await sut.execute({
      orderId: 'order-1',
      userId: 'user-1',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value.message).toBe('Wallet RPC offline');
    }
  });
});
