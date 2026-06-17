import { NestFactory } from '@nestjs/core';
import { ValidationPipe, BadRequestException, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { json, urlencoded } from 'express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './shared/http/exception-filter';
import { TransformInterceptor } from './shared/http/transform.interceptor';
import { LoggingInterceptor } from './shared/http/logging.interceptor';
import { EitherInterceptor } from './shared/http/response.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    cors: {
      origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
      credentials: true,
    },
  });

  app.use(helmet());
  app.use(json({ limit: '1mb' }));
  app.use(urlencoded({ extended: true, limit: '1mb' }));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
      exceptionFactory: (errors) => {
        const logger = new Logger('ValidationPipe');
        const formatted = errors.map((e) => ({
          property: e.property,
          value: e.value,
          constraints: e.constraints,
          target: e.target,
        }));
        logger.warn(`Validation failed: ${JSON.stringify(formatted)}`);
        return new BadRequestException({
          code: 'VALIDATION_ERROR',
          message: `Validation failed for ${errors.map((e) => e.property).join(', ')}`,
          errors: formatted,
        });
      },
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new EitherInterceptor());
  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalInterceptors(new LoggingInterceptor());

  const config = new DocumentBuilder()
    .setTitle('FreeBay API')
    .setDescription(
      'FreeBay - C2C Hybrid Marketplace\n\n' +
        'All successful responses are wrapped in: `{ "success": true, "data": <response> }`\n' +
        'All error responses follow: `{ "success": false, "error": { "code", "message" }, "timestamp", "path" }`',
    )
    .setVersion('1.0')
    .addServer(`http://localhost:${process.env.PORT || 3000}`, 'Local development')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(` FreeBay API running on http://localhost:${port}`);
  console.log(` Swagger: http://localhost:${port}/api`);
}
bootstrap();
