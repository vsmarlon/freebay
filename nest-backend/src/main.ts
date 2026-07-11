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

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    cors: {
      origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
      credentials: true,
    },
  });

  app.use(helmet());
  app.use(json({ limit: '5mb' }));
  app.use(urlencoded({ extended: true, limit: '5mb' }));

  app.useGlobalPipes(createValidationPipe());
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new LoggingInterceptor());
  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalInterceptors(new EitherInterceptor());

  setupSwagger(app);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(` FreeBay API running on http://localhost:${port}`);
  console.log(` Swagger: http://localhost:${port}/api`);
}
bootstrap();
