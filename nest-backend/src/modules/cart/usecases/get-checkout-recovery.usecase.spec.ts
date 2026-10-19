import { PaymentGroupStatus } from '@prisma/client';
import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { PaymentGroupDatabaseRepository } from '@/modules/payments/data/repositories/payment-group-database.repository';
import { GetCheckoutRecoveryUseCase } from './get-checkout-recovery.usecase';

describe('GetCheckoutRecoveryUseCase', () => {
  const group = {
    id: 'group-1', buyerId: 'buyer-1', amount: 12500, currency: 'usd',
    status: PaymentGroupStatus.PENDING, stripePaymentIntentId: 'pi_1', stripeSessionId: null,
    clientSecret: 'pi_1_secret_value', checkoutUrl: null,
    expiresAt: new Date(Date.now() + 60_000),
    orders: [{ orderId: 'order-1' }],
  };

  it('returns the same live attempt references for cross-client recovery', async () => {
    const findLatestOpenForBuyer = jest.fn().mockResolvedValue(right({ group, mode: 'intent' }));
    const module = await Test.createTestingModule({
      providers: [GetCheckoutRecoveryUseCase, {
        provide: PaymentGroupDatabaseRepository, useValue: { findLatestOpenForBuyer },
      }],
    }).compile();
    const useCase = module.get(GetCheckoutRecoveryUseCase);

    await expect(useCase.execute({ userId: 'buyer-1', mode: 'intent' })).resolves.toEqual(right({
      status: 'CHECKING', paymentGroupId: 'group-1', orderIds: ['order-1'], totalAmount: 12500,
      checkoutUrl: null, paymentIntentClientSecret: 'pi_1_secret_value', expiresAt: group.expiresAt,
    }));
    await expect(useCase.execute({ userId: 'buyer-1', mode: 'session' })).resolves.toEqual(right({
      status: 'CHECKING', paymentGroupId: 'group-1', orderIds: ['order-1'], totalAmount: 12500,
      checkoutUrl: null, paymentIntentClientSecret: 'pi_1_secret_value', expiresAt: group.expiresAt,
    }));
    expect(findLatestOpenForBuyer).toHaveBeenCalledWith('buyer-1');
  });

  it('keeps expired and identity-less attempts checking without returning a credential', async () => {
    const expired = { ...group, expiresAt: new Date(Date.now() - 60_000), clientSecret: null };
    const module = await Test.createTestingModule({
      providers: [GetCheckoutRecoveryUseCase, {
        provide: PaymentGroupDatabaseRepository,
        useValue: { findLatestOpenForBuyer: jest.fn().mockResolvedValue(right({ group: expired, mode: 'intent' })) },
      }],
    }).compile();
    const useCase = module.get(GetCheckoutRecoveryUseCase);

    const result = await useCase.execute({ userId: 'buyer-1', mode: 'intent' });

    expect(result.isRight() && result.value).toMatchObject({
      status: 'CHECKING', paymentGroupId: 'group-1', paymentIntentClientSecret: null,
    });
  });

  it('returns paid history without blocking a populated new cart', async () => {
    const paid = { ...group, status: PaymentGroupStatus.PAID };
    const module = await Test.createTestingModule({
      providers: [GetCheckoutRecoveryUseCase, {
        provide: PaymentGroupDatabaseRepository,
        useValue: { findLatestOpenForBuyer: jest.fn().mockResolvedValue(right({ group: paid, mode: 'intent' })) },
      }],
    }).compile();

    await expect(module.get(GetCheckoutRecoveryUseCase).execute({ userId: 'buyer-1', mode: 'session' }))
      .resolves.toEqual(right({
        status: 'PAID', paymentGroupId: 'group-1', orderIds: ['order-1'], totalAmount: 12500,
        checkoutUrl: null, paymentIntentClientSecret: null, expiresAt: group.expiresAt,
      }));
  });
});
