import { Body, Controller, NotFoundException, HttpStatus } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { PostAuth, CurrentUserId } from '@/shared/decorators';
import { unwrap } from '@/shared/http/unwrap';
import { PushTestUseCase } from './usecases/push-test.usecase';
import { PushTestDTO } from './dtos/notification.dto';

@ApiTags('Notifications')
@Controller('notifications/dev')
export class NotificationsDevController {
  constructor(
    private readonly pushTestUseCase: PushTestUseCase,
    private readonly config: ConfigService,
  ) {}

  /**
   * Dev/test-only diagnostic push. The module does not register this controller
   * in production; this 404 is the fail-closed backstop if that ever drifts.
   */
  @PostAuth('push-test', {
    summary: 'Send a diagnostic push to your own devices (dev/test only)',
    description:
      'Disabled and unregistered in production. Reports Firebase acceptance only — ' +
      'device delivery must be confirmed on the device. Targets only the requester tokens.',
    bodyType: PushTestDTO,
    httpCode: HttpStatus.OK,
    throttle: { short: { limit: 3, ttl: 60_000 } },
    errors: [{ status: 404, description: 'Not available in production' }],
  })
  async pushTest(@CurrentUserId() userId: string, @Body() body: PushTestDTO) {
    if (this.config.get('NODE_ENV') === 'production') throw new NotFoundException();
    return unwrap(await this.pushTestUseCase.execute(userId, body));
  }
}
