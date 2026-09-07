import { ConsoleLogger } from '@nestjs/common';
import { getRequestContext } from './request-context';

export class AppLogger extends ConsoleLogger {
  protected formatMessage(
    logLevel: Parameters<ConsoleLogger['formatMessage']>[0],
    message: unknown,
    pidMessage: string,
    formattedLogLevel: string,
    contextMessage: string,
    timestampDiff: string,
  ): string {
    const context = getRequestContext();
    const tags = context
      ? `[req:${context.requestId}${context.userId ? ` user:${context.userId}` : ''}] `
      : '';

    return super.formatMessage(
      logLevel,
      message,
      pidMessage,
      formattedLogLevel,
      `${contextMessage}${tags}`,
      timestampDiff,
    );
  }
}
