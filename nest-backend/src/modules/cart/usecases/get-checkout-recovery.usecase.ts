import { Injectable } from '@nestjs/common';
import { PaymentGroupStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PaymentGroupDatabaseRepository } from '@/modules/payments/data/repositories/payment-group-database.repository';
import { CheckoutRecoveryInput, CheckoutRecoveryOutput } from '../dtos/cart.dto';

@Injectable()
export class GetCheckoutRecoveryUseCase {
  constructor(private readonly paymentGroups: PaymentGroupDatabaseRepository) {}

  async execute(input: CheckoutRecoveryInput): Promise<Either<AppError, CheckoutRecoveryOutput | null>> {
    const result = await this.paymentGroups.findLatestOpenForBuyer(input.userId);
    if (result.isLeft()) return left(result.value);
    const attempt = result.value;
    if (!attempt) return right(null);

    const { group } = attempt;
    const resumable = group.status === PaymentGroupStatus.PENDING &&
      group.expiresAt !== null && group.expiresAt.getTime() > Date.now();
    return right({
      status: group.status === PaymentGroupStatus.PAID ? 'PAID' : 'CHECKING',
      paymentGroupId: group.id,
      orderIds: group.orders.map(({ orderId }) => orderId),
      totalAmount: group.amount,
      checkoutUrl: resumable ? group.checkoutUrl : null,
      paymentIntentClientSecret: resumable ? group.clientSecret : null,
      expiresAt: group.expiresAt,
    });
  }
}
