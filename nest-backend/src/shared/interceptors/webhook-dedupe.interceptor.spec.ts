import { Test, TestingModule } from "@nestjs/testing";
import { CallHandler, ExecutionContext } from "@nestjs/common";
import { createExecutionContext } from "@/shared/testing/test-doubles";
import { of, throwError, lastValueFrom } from "rxjs";
import { WebhookDedupeInterceptor, WEBHOOK_DEDUPE_TTL_SECONDS } from "./webhook-dedupe.interceptor";
import { RedisService } from "@/shared/infra/redis/redis.service";
import { left, right } from "@/shared/core/either";

describe("WebhookDedupeInterceptor", () => {
  let interceptor: WebhookDedupeInterceptor;
  let mockRedis: { get: jest.Mock; add: jest.Mock; setIfAbsent: jest.Mock; del: jest.Mock };

  const createContext = (
    stripeEvent: { id: string } | undefined,
  ): ExecutionContext => {
    const request = { stripeEvent };
    return createExecutionContext({ request });
  };

  beforeEach(async () => {
    mockRedis = {
      get: jest.fn().mockResolvedValue(null),
      add: jest.fn().mockResolvedValue(undefined),
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
    mockRedis.get.mockResolvedValue('done');
    const handler: CallHandler = { handle: jest.fn() };

    const result = await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(result).toEqual({ processed: false });
    expect(handler.handle).not.toHaveBeenCalled();
    expect(mockRedis.add).not.toHaveBeenCalled();
  });

  it("stores the done key only after the handler succeeds", async () => {
    const events: string[] = [];
    const handler: CallHandler = {
      handle: jest.fn(() => {
        events.push('handler');
        return of(right({ processed: true }));
      }),
    };
    mockRedis.add.mockImplementation(async () => { events.push('done'); });

    const result = await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(result).toEqual(right({ processed: true }));
    expect(handler.handle).toHaveBeenCalled();
    expect(mockRedis.get).toHaveBeenCalledWith('webhook:evt_123');
    expect(mockRedis.add).toHaveBeenCalledWith(
      "webhook:evt_123",
      "1",
      WEBHOOK_DEDUPE_TTL_SECONDS,
    );
    expect(events).toEqual(['handler', 'done']);
  });

  it("does not store a done key when the handler throws", async () => {
    const originalError = new Error("boom");
    const handler: CallHandler = {
      handle: jest.fn(() => throwError(() => originalError)),
    };

    const observable = await interceptor.intercept(
      createContext({ id: "evt_123" }),
      handler,
    );

    await new Promise<void>((resolve, reject) => {
      observable.subscribe({
        error: (error: unknown) => {
          try {
            expect(error).toBe(originalError);
            resolve();
          } catch (assertionError: unknown) {
            reject(assertionError);
          }
        },
      });
    });

    expect(mockRedis.add).not.toHaveBeenCalled();
  });

  it("does not store a done key when the handler emits Left", async () => {
    const handler: CallHandler = {
      handle: jest.fn(() => of(left(new Error("failed")))),
    };

    await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(mockRedis.add).not.toHaveBeenCalled();
  });

  it("retains the key when the handler emits Right", async () => {
    const handler: CallHandler = {
      handle: jest.fn(() => of(right({ processed: true }))),
    };

    await lastValueFrom(
      await interceptor.intercept(createContext({ id: "evt_123" }), handler),
    );

    expect(mockRedis.add).toHaveBeenCalledWith('webhook:evt_123', '1', WEBHOOK_DEDUPE_TTL_SECONDS);
  });

  it("deduplicates a v2 event using its event id", async () => {
    mockRedis.get.mockResolvedValue('done');
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
    expect(mockRedis.get).toHaveBeenCalledWith("webhook:evt_v2_account");
    expect(handler.handle).not.toHaveBeenCalled();
  });
});
