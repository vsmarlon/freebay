import { Logger } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import { UserDatabaseRepository } from "@/modules/auth/data/repositories/user-database.repository";
import { PaymentLineItem } from "@/modules/payments/types/payment-provider.types";
import { StripeProvider } from "@/modules/payments/providers/stripe-provider";
import { CheckoutMode } from "../../dtos/cart.dto";
import { PlannedCartItem } from "./checkout-cart.types";

export type CheckoutPayment = { attach: {
  stripeSessionId?: string;
  stripePaymentIntentId?: string;
  checkoutUrl?: string;
  expiresAt?: Date;
  clientSecret?: string;
} };

export class CheckoutCartPayment {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly paymentProvider: StripeProvider,
    private readonly logger: Logger,
  ) {}

  create(
    mode: CheckoutMode,
    groupId: string,
    userId: string,
    amount: number,
    planned: PlannedCartItem[],
    customerTaxId: string | null,
  ): Promise<Either<AppError, CheckoutPayment>> {
    return mode === "session"
      ? this.createSession(groupId, userId, amount, planned, customerTaxId)
      : this.createIntent(groupId, userId, amount);
  }

  private async createSession(groupId: string, userId: string, amount: number, planned: PlannedCartItem[], customerTaxId: string | null): Promise<Either<AppError, CheckoutPayment>> {
    const userResult = await this.userRepository.findPaymentInfo(userId);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value ?? { displayName: "", email: "", cpf: null };
    const lineItems: PaymentLineItem[] = planned.map((item) => ({ name: item.productTitle, amount: item.amount / item.quantity, quantity: item.quantity }));
    const sessionResult = await this.paymentProvider.createPaymentSession({
      paymentGroupId: groupId,
      amount,
      currency: "brl",
      customerEmail: user.email ?? undefined,
      customerName: user.displayName,
      customerTaxId: customerTaxId ?? undefined,
      idempotencyKey: `group-session:${groupId}`,
      lineItems,
      successUrl: `${process.env.APP_URL}/payments/success?paymentGroupId=${groupId}`,
      cancelUrl: `${process.env.APP_URL}/payments/cancel?paymentGroupId=${groupId}`,
    });
    if (sessionResult.isLeft()) {
      this.logger.error(`Cart payment session failed: ${sessionResult.value.message}`);
      return left(sessionResult.value);
    }
    return right({ attach: {
      stripeSessionId: sessionResult.value.stripeSessionId,
      checkoutUrl: sessionResult.value.checkoutUrl,
      expiresAt: sessionResult.value.expiresAt,
    } });
  }

  private async createIntent(groupId: string, userId: string, amount: number): Promise<Either<AppError, CheckoutPayment>> {
    const userResult = await this.userRepository.findPaymentInfo(userId);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value ?? { displayName: "", email: "", cpf: null };
    const intentResult = await this.paymentProvider.createPaymentIntent({
      paymentGroupId: groupId,
      amount,
      currency: "brl",
      receiptEmail: user.email ?? undefined,
      idempotencyKey: `group-pi:${groupId}`,
    });
    if (intentResult.isLeft()) {
      this.logger.error(`Cart payment intent failed: ${intentResult.value.message}`);
      return left(intentResult.value);
    }
    return right({ attach: {
      stripePaymentIntentId: intentResult.value.paymentIntentId,
      clientSecret: intentResult.value.clientSecret,
    } });
  }
}
