import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { MODULE_METADATA } from '@nestjs/common/constants';
import { ConfigService } from '@nestjs/config';
import { right } from '@/shared/core/either';
import { NotificationsDevController } from './notifications-dev.controller';
import { PushTestUseCase } from './usecases/push-test.usecase';
import { isProductionEnvironment, NotificationsModule } from './notifications.module';
import { PushDeliveryResult, PushDeliveryStatus } from './types/push-delivery.types';

describe('NotificationsDevController', () => {
  const delivery: PushDeliveryResult = {
    status: PushDeliveryStatus.NoTokens,
    deviceCount: 0,
    acceptedCount: 0,
    rejectedCount: 0,
    errors: [],
  };
  let moduleRef: TestingModule;
  let execute: jest.Mock;

  afterEach(async () => {
    await moduleRef.close();
  });

  async function buildController(nodeEnv: string) {
    execute = jest.fn().mockResolvedValue(right(delivery));
    moduleRef = await Test.createTestingModule({
      providers: [
        NotificationsDevController,
        { provide: PushTestUseCase, useValue: { execute } },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => (key === 'NODE_ENV' ? nodeEnv : undefined)),
          },
        },
      ],
    }).compile();
    return moduleRef.get(NotificationsDevController);
  }

  it('answers 404 and never reaches the use case when NODE_ENV is production', async () => {
    const controller = await buildController('production');

    await expect(controller.pushTest('user-id', {})).rejects.toThrow(NotFoundException);
    expect(execute).not.toHaveBeenCalled();
  });

  it('returns the unwrapped delivery result to the authenticated requester in development', async () => {
    const controller = await buildController('development');

    await expect(controller.pushTest('user-id', {})).resolves.toBe(delivery);
    expect(execute).toHaveBeenCalledWith('user-id', {});
  });

  it('marks only production as the environment where dev routing is forbidden', () => {
    expect(isProductionEnvironment('production')).toBe(true);
    expect(isProductionEnvironment('development')).toBe(false);
    expect(isProductionEnvironment('test')).toBe(false);
    const originalNodeEnv = process.env.NODE_ENV;
    delete process.env.NODE_ENV;
    expect(isProductionEnvironment(undefined)).toBe(false);
    process.env.NODE_ENV = originalNodeEnv;
  });

  it('registers the dev controller on the module in the test environment', () => {
    const controllers = Reflect.getMetadata(MODULE_METADATA.CONTROLLERS, NotificationsModule);

    expect(controllers).toContain(NotificationsDevController);
  });
});
