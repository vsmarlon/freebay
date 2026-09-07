import { ValidationPipe, BadRequestException } from '@nestjs/common';

export function createValidationPipe(): ValidationPipe {
  return new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    transformOptions: { enableImplicitConversion: true },
    exceptionFactory: (errors) => {
      const formatted = errors.map((e) => ({
        property: e.property,
        constraints: e.constraints,
      }));
      return new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: `Validation failed for ${errors.map((e) => e.property).join(', ')}`,
        errors: formatted,
      });
    },
  });
}
