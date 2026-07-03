import { ValidationPipe, BadRequestException, Logger } from '@nestjs/common';

export function createValidationPipe(): ValidationPipe {
  return new ValidationPipe({
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
  });
}
