import { Test, TestingModule } from "@nestjs/testing";
import { right, left } from "@/shared/core/either";
import { PaymentProviderError } from "@/shared/core/errors";
import { TransactionDatabaseRepository } from "../data/repositories/transaction-database.repository";
import { PrismaOrderRepository } from "../../orders/data/repositories/order-database.repository";
import { SellerPayoutService } from "../services/seller-payout.service";
import { isFullRefund, ProcessRefundUseCase } from "./process-refund.usecase";

describe("ProcessRefundUseCase", () => {
  it("identifies partial refunds without treating them as full refunds", () => {
    expect(
      isFullRefund({ refunded: false, amount: 1000, amount_refunded: 500 }),
    ).toBe(false);
    expect(
      isFullRefund({ refunded: false, amount: 1000, amount_refunded: 1000 }),
    ).toBe(true);
  });

  it("does not cancel the order for a partial refund event", async () => {
    const transactionRepo = { findByChargeId: jest.fn() };
    const orderRepo = { refundOrder: jest.fn() };
    const payoutService = { reverseForOrder: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessRefundUseCase,
        { provide: TransactionDatabaseRepository, useValue: transactionRepo },
        { provide: PrismaOrderRepository, useValue: orderRepo },
        { provide: SellerPayoutService, useValue: payoutService },
      ],
    }).compile();

    const result = await module
      .get(ProcessRefundUseCase)
      .execute("ch_1", false);

    expect(result.isRight()).toBe(true);
    expect(transactionRepo.findByChargeId).not.toHaveBeenCalled();
    expect(payoutService.reverseForOrder).not.toHaveBeenCalled();
    expect(orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it("does not cancel the order when transfer reversal fails", async () => {
    const transactionRepo = {
      findByChargeId: jest.fn().mockResolvedValue(
        right({
          order: {
            id: "order-1",
            productId: "product-1",
            buyerId: "buyer-1",
            amount: 1000,
            status: "CONFIRMED",
            quantity: 1,
            sellerId: "seller-1",
            sellerAmount: 900,
          },
        }),
      ),
    };
    const orderRepo = { refundOrder: jest.fn() };
    const payoutService = {
      reverseForOrder: jest
        .fn()
        .mockResolvedValue(left(new PaymentProviderError())),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessRefundUseCase,
        { provide: TransactionDatabaseRepository, useValue: transactionRepo },
        { provide: PrismaOrderRepository, useValue: orderRepo },
        { provide: SellerPayoutService, useValue: payoutService },
      ],
    }).compile();

    const result = await module.get(ProcessRefundUseCase).execute("ch_1", true);

    expect(result.isLeft()).toBe(true);
    expect(orderRepo.refundOrder).not.toHaveBeenCalled();
  });

  it("reverses a transferred release without debiting the seller again", async () => {
    const transactionRepo = {
      findByChargeId: jest.fn().mockResolvedValue(
        right({
          transferId: "tr_1",
          order: {
            id: "order-1",
            productId: "product-1",
            buyerId: "buyer-1",
            amount: 1000,
            status: "COMPLETED",
            escrowStatus: "RELEASED",
            quantity: 1,
            sellerId: "seller-1",
            sellerAmount: 900,
          },
        }),
      ),
    };
    const orderRepo = {
      refundOrder: jest.fn().mockResolvedValue(right(undefined)),
    };
    const payoutService = {
      reverseForOrder: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessRefundUseCase,
        { provide: TransactionDatabaseRepository, useValue: transactionRepo },
        { provide: PrismaOrderRepository, useValue: orderRepo },
        { provide: SellerPayoutService, useValue: payoutService },
      ],
    }).compile();

    const result = await module.get(ProcessRefundUseCase).execute("ch_1", true);

    expect(result.isRight()).toBe(true);
    expect(payoutService.reverseForOrder).toHaveBeenCalledWith("order-1");
    expect(orderRepo.refundOrder).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "COMPLETED",
        escrowStatus: "RELEASED",
        transferId: "tr_1",
      }),
    );
  });

  it("does not reverse or debit again when a refund retry sees a cancelled order", async () => {
    const transactionRepo = {
      findByChargeId: jest.fn().mockResolvedValue(
        right({
          order: {
            id: "order-1",
            productId: "product-1",
            buyerId: "buyer-1",
            amount: 1000,
            status: "CANCELLED",
            escrowStatus: "REFUNDED",
            quantity: 1,
            sellerId: "seller-1",
            sellerAmount: 900,
          },
        }),
      ),
    };
    const orderRepo = { refundOrder: jest.fn() };
    const payoutService = { reverseForOrder: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessRefundUseCase,
        { provide: TransactionDatabaseRepository, useValue: transactionRepo },
        { provide: PrismaOrderRepository, useValue: orderRepo },
        { provide: SellerPayoutService, useValue: payoutService },
      ],
    }).compile();

    const result = await module.get(ProcessRefundUseCase).execute("ch_1", true);

    expect(result.isRight()).toBe(true);
    expect(payoutService.reverseForOrder).not.toHaveBeenCalled();
    expect(orderRepo.refundOrder).not.toHaveBeenCalled();
  });
});
