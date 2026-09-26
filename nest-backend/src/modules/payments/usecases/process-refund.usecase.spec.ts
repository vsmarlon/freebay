import { Test, TestingModule } from "@nestjs/testing";
import { right, left } from "@/shared/core/either";
import { PaymentProviderError } from "@/shared/core/errors";
import { TransactionDatabaseRepository } from "../data/repositories/transaction-database.repository";
import { PrismaOrderRepository } from "../../orders/data/repositories/order-database.repository";
import { SellerPayoutService } from "../services/seller-payout.service";
import { isFullRefund, ProcessRefundUseCase } from "./process-refund.usecase";

describe("ProcessRefundUseCase", () => {
  type Mocks = {
    transactionRepo: { findByChargeId: jest.Mock };
    orderRepo: { refundOrder: jest.Mock };
    payoutService: { reverseForOrder: jest.Mock };
  };

  const buildTransaction = (overrides: {
    transferId?: string;
    status: string;
    escrowStatus?: string;
  }) => ({
    transferId: overrides.transferId,
    order: {
      id: "order-1",
      productId: "product-1",
      buyerId: "buyer-1",
      amount: 1000,
      status: overrides.status,
      escrowStatus: overrides.escrowStatus,
      quantity: 1,
      sellerId: "seller-1",
      sellerAmount: 900,
    },
  });

  const compileSubject = async (mocks: Mocks): Promise<ProcessRefundUseCase> => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessRefundUseCase,
        { provide: TransactionDatabaseRepository, useValue: mocks.transactionRepo },
        { provide: PrismaOrderRepository, useValue: mocks.orderRepo },
        { provide: SellerPayoutService, useValue: mocks.payoutService },
      ],
    }).compile();

    return module.get(ProcessRefundUseCase);
  };

  it("identifies partial refunds without treating them as full refunds", () => {
    expect(
      isFullRefund({ refunded: false, amount: 1000, amount_refunded: 500 }),
    ).toBe(false);
    expect(
      isFullRefund({ refunded: false, amount: 1000, amount_refunded: 1000 }),
    ).toBe(true);
  });

  it("does not cancel the order for a partial refund event", async () => {
    const mocks: Mocks = {
      transactionRepo: { findByChargeId: jest.fn() },
      orderRepo: { refundOrder: jest.fn() },
      payoutService: { reverseForOrder: jest.fn() },
    };
    const result = await (await compileSubject(mocks)).execute("ch_1", false);

    expect(result.isRight()).toBe(true);
    expect(mocks.transactionRepo.findByChargeId).not.toHaveBeenCalled();
    expect(mocks.payoutService.reverseForOrder).not.toHaveBeenCalled();
    expect(mocks.orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it("does not cancel the order when transfer reversal fails", async () => {
    const mocks: Mocks = {
      transactionRepo: {
        findByChargeId: jest.fn().mockResolvedValue(
          right(buildTransaction({ status: "CONFIRMED" })),
        ),
      },
      orderRepo: { refundOrder: jest.fn() },
      payoutService: {
        reverseForOrder: jest.fn().mockResolvedValue(left(new PaymentProviderError())),
      },
    };
    const result = await (await compileSubject(mocks)).execute("ch_1", true);

    expect(result.isLeft()).toBe(true);
    expect(mocks.orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it("reverses a transferred release without debiting the seller again", async () => {
    const mocks: Mocks = {
      transactionRepo: {
        findByChargeId: jest.fn().mockResolvedValue(
          right(buildTransaction({ transferId: "tr_1", status: "COMPLETED", escrowStatus: "RELEASED" })),
        ),
      },
      orderRepo: { refundOrder: jest.fn().mockResolvedValue(right(undefined)) },
      payoutService: { reverseForOrder: jest.fn().mockResolvedValue(right(undefined)) },
    };
    const result = await (await compileSubject(mocks)).execute("ch_1", true);

    expect(result.isRight()).toBe(true);
    expect(mocks.payoutService.reverseForOrder).toHaveBeenCalledWith("order-1");
    expect(mocks.orderRepo.refundOrder).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "COMPLETED",
        escrowStatus: "RELEASED",
        transferId: "tr_1",
      }),
    );
  });

  it("does not reverse or debit again when a refund retry sees a cancelled order", async () => {
    const mocks: Mocks = {
      transactionRepo: {
        findByChargeId: jest.fn().mockResolvedValue(
          right(buildTransaction({ status: "CANCELLED", escrowStatus: "REFUNDED" })),
        ),
      },
      orderRepo: { refundOrder: jest.fn() },
      payoutService: { reverseForOrder: jest.fn() },
    };
    const result = await (await compileSubject(mocks)).execute("ch_1", true);

    expect(result.isRight()).toBe(true);
    expect(mocks.payoutService.reverseForOrder).not.toHaveBeenCalled();
    expect(mocks.orderRepo.refundOrder).not.toHaveBeenCalled();
  });
});
