import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FcmService } from '../fcm.service';
import { PushDeliveryResult, PushTestInput } from '../types/push-delivery.types';

const DEFAULT_TITLE = 'Teste de push do FreeBay';
const DEFAULT_BODY = 'Se você recebeu isto, o envio push está funcionando.';

@Injectable()
export class PushTestUseCase {
  constructor(private readonly fcm: FcmService) {}

  /**
   * Sends a diagnostic push to the requester's own registered devices.
   * The payload deliberately carries no `action`: tapping the notification
   * opens the notifications page instead of any feature route.
   */
  async execute(userId: string, input: PushTestInput): Promise<Either<AppError, PushDeliveryResult>> {
    const data: Record<string, string> = input.type ? { type: input.type } : {};
    const result = await this.fcm.sendNotification(
      userId,
      input.title ?? DEFAULT_TITLE,
      input.body ?? DEFAULT_BODY,
      data,
    );
    return right(result);
  }
}
