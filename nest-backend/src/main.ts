import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { json, urlencoded } from 'express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './shared/http/exception-filter';
import { TransformInterceptor } from './shared/http/transform.interceptor';
import { LoggingInterceptor } from './shared/http/logging.interceptor';
import { EitherInterceptor } from './shared/http/response.interceptor';
import { createValidationPipe } from './shared/http/validation-pipe.factory';
import { setupSwagger } from './shared/swagger/swagger.setup';
import { AppLogger } from './shared/observability/app-logger';
import { requestContextMiddleware } from './shared/observability/request-context';
import { initSentry, captureError } from './shared/observability/sentry';
import { isAllowedOrigin, parseAllowedOrigins } from './shared/http/origin-policy';

async function bootstrap() {
  initSentry();

  const processLogger = new AppLogger('Process');
  process.on('unhandledRejection', (reason) => {
    processLogger.error('Unhandled rejection');
    captureError(reason, { scope: 'unhandledRejection' });
  });
  process.on('uncaughtException', (error) => {
    processLogger.error(`Uncaught exception: ${error.name}`);
    captureError(error, { scope: 'uncaughtException' });
  });

  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    cors: {
      origin: (origin: string | undefined, callback: (error: Error | null, allowed?: boolean) => void) => {
        callback(null, isAllowedOrigin(origin, parseAllowedOrigins(
          process.env.ALLOWED_ORIGINS || process.env.WEB_APP_URL || process.env.WEB_ALLOWED_ORIGIN || 'http://localhost:3000',
        )));
      },
      credentials: true,
    },
    // Stripe signature verification needs the exact raw payload, not the JSON-parsed body
    rawBody: true,
    logger: new AppLogger(),
  });
  const trustedProxies = process.env.TRUST_PROXY_CIDRS?.split(',').map((value) => value.trim()).filter(Boolean);
  if (trustedProxies?.length) app.set('trust proxy', trustedProxies);

  // Before helmet so guards, interceptors and the exception filter all see the request id
  app.use(requestContextMiddleware);
  app.use(helmet());
  app.use(json({ limit: '5mb' }));
  app.use(urlencoded({ extended: true, limit: '5mb' }));

  app.useGlobalPipes(createValidationPipe());
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new LoggingInterceptor());
  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalInterceptors(new EitherInterceptor());

  app.enableShutdownHooks();

  const swaggerEnabled = setupSwagger(app);

  const port = process.env.PORT || 3000;
  const host = process.env.HOST;
  if (host) await app.listen(port, host);
  else await app.listen(port);

  const logger = new AppLogger('Bootstrap');
  logger.log(`FreeBay API listening on port ${port}`);
  if (swaggerEnabled) logger.log(`Swagger: http://localhost:${port}/api`);
}
bootstrap();
