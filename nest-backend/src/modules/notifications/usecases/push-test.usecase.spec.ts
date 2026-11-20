import { Test, TestingModule } from '@nestjs/testing';
import { PushTestUseCase } from './push-test.usecase';
import { FcmService } from '../fcm.service';
import {
  PushDeliveryResult,
  PushDeliveryStatus,
  PushTestInput,
  PushTestType,
} from '../types/push-delivery.types';

describe('PushTestUseCase', () => {
  const delivery: PushDeliveryResult = {
    status: PushDeliveryStatus.Submitted,
    deviceCount: 1,
    acceptedCount: 1,
    rejectedCount: 0,
    errors: [],
  };
  let moduleRef: TestingModule;
  let sendNotification: jest.Mock;
  let sut: PushTestUseCase;

  beforeEach(async () => {
    sendNotification = jest.fn().mockResolvedValue(delivery);
    const builder = Test.createTestingModule({
      providers: [
        PushTestUseCase,
        { provide: FcmService, useValue: { sendNotification } },
      ],
    });
    moduleRef = await builder.compile();
    sut = moduleRef.get(PushTestUseCase);
  });

  afterEach(async () => {
    await moduleRef.close();
  });

  it('sends the fixed diagnostic defaults with no category when the input is empty', async () => {
    const result = await sut.execute('user-id', {});

    expect(sendNotification).toHaveBeenCalledWith(
      'user-id',
      'Teste de push do FreeBay',
      'Se você recebeu isto, o envio push está funcionando.',
      {},
    );
    expect(result.isRight()).toBe(true);
    expect(result.value).toBe(delivery);
  });

  it('passes the caller title, body and category through to the real send path', async () => {
    const input: PushTestInput = { title: 'Custom title', body: 'Custom body', type: PushTestType.Message };

    await sut.execute('user-id', input);

    expect(sendNotification).toHaveBeenCalledWith('user-id', 'Custom title', 'Custom body', { type: 'MESSAGE' });
  });
});
