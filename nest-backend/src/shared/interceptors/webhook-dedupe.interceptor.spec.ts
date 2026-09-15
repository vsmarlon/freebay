import { Test, TestingModule } from "@nestjs/testing";
import { CallHandler, ExecutionContext } from "@nestjs/common";
import { createExecutionContext } from "@/shared/testing/test-doubles";
import { of, throwError, lastValueFrom } from "rxjs";
import { WebhookDedupeInterceptor } from "./webhook-dedupe.interceptor";
import { RedisService } from "@/shared/infra/redis/redis.service";
import { left, right } from "@/shared/core/either";

describe("WebhookDedupeInterceptor", () => {
  let interceptor: WebhookDedupeInterceptor;
  let mockRedis: { setIfAbsent: jest.Mock; del: jest.Mock };

  const createContext = (
    stripeEvent: { id: string } | undefined,
  ): ExecutionContext => {
    const request = { stripeEvent };
    return createExecutionContext({ request });
  };

  beforeEach(async () => {
    mockRedis = {
      setIfAbsent: jest.fn().mockResolvedValue(true),
      del: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhookDedupeInterceptor,
        { provide: RedisService, useValue: mockRedis },
      ],
    }).compile();

    interceptor = module.get<WebhookDedupeInterceptor>(
      WebhookDedupeInterceptor,
    );
  });

  it("skips the handler and returns processed false when the event key already exists", async () => {
    mockRedis.setIfAbsent.mockResolvedValue(false);
    const handler: CallHandler = { handle: jest.fn() };

    const result = await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(result).toEqual({ processed: false });
    expect(handler.handle).not.toHaveBeenCalled();
    expect(mockRedis.del).not.toHaveBeenCalled();
  });

  it("atomically claims the key before running the handler", async () => {
    const handler: CallHandler = {
      handle: jest.fn(() => of({ processed: true })),
    };

    const result = await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(result).toEqual({ processed: true });
    expect(handler.handle).toHaveBeenCalled();
    expect(mockRedis.setIfAbsent).toHaveBeenCalledWith(
      "webhook:evt_123",
      "1",
      86400,
    );
  });

  it("releases the key before re-emitting the handler error", async () => {
    const originalError = new Error("boom");
    const events: string[] = [];
    const handler: CallHandler = {
      handle: jest.fn(() => throwError(() => originalError)),
    };
    mockRedis.del.mockImplementation(async () => {
      await Promise.resolve();
      events.push("deleted");
    });

    const observable = await interceptor.intercept(
      createContext({ id: "evt_123" }),
      handler,
    );

    await new Promise<void>((resolve, reject) => {
      observable.subscribe({
        error: (error: unknown) => {
          try {
            expect(error).toBe(originalError);
            events.push("error");
            resolve();
          } catch (assertionError: unknown) {
            reject(assertionError);
          }
        },
      });
    });

    expect(mockRedis.del).toHaveBeenCalledWith("webhook:evt_123");
    expect(events).toEqual(["deleted", "error"]);
  });

  it("releases the key when the handler emits Left", async () => {
    const handler: CallHandler = {
      handle: jest.fn(() => of(left(new Error("failed")))),
    };

    await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(mockRedis.del).toHaveBeenCalledWith("webhook:evt_123");
  });

  it("retains the key when the handler emits Right", async () => {
    const handler: CallHandler = {
      handle: jest.fn(() => of(right({ processed: true }))),
    };

    await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(mockRedis.del).not.toHaveBeenCalled();
  });

  it("deduplicates a v2 event using its event id", async () => {
    mockRedis.setIfAbsent.mockResolvedValue(false);
    const handler: CallHandler = { handle: jest.fn() };
    const v2Event = {
      id: "evt_v2_account",
      type: "v2.core.account.updated",
      related_object: { id: "acct_1", type: "v2.core.account" },
    };

    const result = await lastValueFrom(
      await interceptor.intercept(createContext(v2Event), handler),
    );

    expect(result).toEqual({ processed: false });
    expect(mockRedis.setIfAbsent).toHaveBeenCalledWith(
      "webhook:evt_v2_account",
      "1",
      86400,
    );
    expect(handler.handle).not.toHaveBeenCalled();
  });
});
