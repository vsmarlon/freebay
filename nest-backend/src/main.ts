import { NestFactory } from '@nestjs/core';
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
import { initSentry } from './shared/observability/sentry';

async function bootstrap() {
  initSentry();

  const app = await NestFactory.create(AppModule, {
    cors: {
      origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
      credentials: true,
    },
    // Stripe signature verification needs the exact raw payload, not the JSON-parsed body
    rawBody: true,
    logger: new AppLogger(),
  });

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

  setupSwagger(app);

  const port = process.env.PORT || 3000;
  await app.listen(port);

  const logger = new AppLogger('Bootstrap');
  logger.log(`FreeBay API running on http://localhost:${port}`);
  logger.log(`Swagger: http://localhost:${port}/api`);
}
bootstrap();
