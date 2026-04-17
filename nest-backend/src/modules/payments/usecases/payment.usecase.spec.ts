import { Test, TestingModule } from '@nestjs/testing';
import { CreatePixPaymentUseCase } from './payment.usecase';
import { PrismaOrderRepository } from '../../orders/repositories/order.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { AbacatePayProvider } from '../providers/abacatepay.provider';
import { NotFoundError, BadRequestError, AppError } from '@/shared/core/errors';
import { right, left } from '@/shared/core/either';

describe('CreatePixPaymentUseCase', () => {
  let sut: CreatePixPaymentUseCase;
  let mockOrderRepository: {
    findById: jest.Mock;
  };
  let mockPrisma: {
    transaction: {
      findFirst: jest.Mock;
      upsert: jest.Mock;
    };
  };
  let mockAbacatePay: {
    createPixCharge: jest.Mock;
  };

  const mockOrder = {
    id: 'order-123',
    buyerId: 'user-buyer',
    sellerId: 'user-seller',
    amount: 10000,
    platformFee: 1000,
    sellerAmount: 9000,
    status: 'PENDING',
  };

  beforeEach(async () => {
    mockOrderRepository = {
      findById: jest.fn(),
    };

    mockPrisma = {
      transaction: {
        findFirst: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
      },
    };

    mockAbacatePay = {
      createPixCharge: jest.fn().mockResolvedValue(
        right({
          id: 'ch_abc123',
          status: 'PENDING' as const,
          pix: {
            key: 'pix-key',
            qrCode: '000201...',
            image: 'data:image/png;base64,...',
          },
        }),
      ),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePixPaymentUseCase,
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AbacatePayProvider, useValue: mockAbacatePay },
      ],
    }).compile();

    sut = module.get<CreatePixPaymentUseCase>(CreatePixPaymentUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should return error if order not found', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(null);

    const input = {
      orderId: 'non-existent-order',
      userId: 'user-buyer',
      customerName: 'John Doe',
      customerTaxId: '12345678901',
      customerEmail: 'john@example.com',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('should return error if user is not the buyer', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(mockOrder);

    const input = {
      orderId: 'order-123',
      userId: 'different-user',
      customerName: 'John Doe',
      customerTaxId: '12345678901',
      customerEmail: 'john@example.com',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
    }
  });

  it('should create PIX payment successfully', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(mockOrder);

    const input = {
      orderId: 'order-123',
      userId: 'user-buyer',
      customerName: 'John Doe',
      customerTaxId: '12345678901',
      customerEmail: 'john@example.com',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.orderId).toBe('order-123');
      expect(result.value.pixQrCode).toBe('000201...');
      expect(result.value.pixImage).toBe('data:image/png;base64,...');
      expect(result.value.expiresAt).toBeInstanceOf(Date);
    }
    expect(mockAbacatePay.createPixCharge).toHaveBeenCalledWith(
      expect.objectContaining({
        correlationID: expect.stringContaining('order-123'),
        value: 10000,
        customer: {
          name: 'John Doe',
          taxID: '12345678901',
          email: 'john@example.com',
        },
      }),
    );
  });

  it('should handle payment provider failure', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(mockOrder);
    mockAbacatePay.createPixCharge = jest.fn().mockResolvedValue(
      left(new AppError('PAYMENT_PROVIDER_ERROR', 'Provider error', 500)),
    );

    const input = {
      orderId: 'order-123',
      userId: 'user-buyer',
      customerName: 'John Doe',
      customerTaxId: '12345678901',
      customerEmail: 'john@example.com',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value.code).toBe('PAYMENT_PROVIDER_ERROR');
    }
  });

  it('should return existing transaction for duplicate idempotency key', async () => {
    mockOrderRepository.findById = jest.fn().mockResolvedValue(mockOrder);
    mockPrisma.transaction.findFirst = jest.fn().mockResolvedValue({
      id: 'tx-existing',
      pixQrCode: 'existing-qr-code',
      pixExpiresAt: new Date('2026-03-30T12:00:00Z'),
    });

    const input = {
      orderId: 'order-123',
      userId: 'user-buyer',
      customerName: 'John Doe',
      customerTaxId: '12345678901',
      customerEmail: 'john@example.com',
      idempotencyKey: 'custom-key-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.pixQrCode).toBe('existing-qr-code');
    }
    // Should NOT call payment provider for duplicate request
    expect(mockAbacatePay.createPixCharge).not.toHaveBeenCalled();
  });
});
