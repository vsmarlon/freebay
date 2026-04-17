import { PipeTransform, ArgumentMetadata, BadRequestException } from '@nestjs/common';
import { ZodSchema } from 'zod';

export class ZodValidationPipe implements PipeTransform {
  constructor(private schema: ZodSchema) {}

  transform(value: unknown, metadata: ArgumentMetadata) {
    if (metadata.type !== 'body') {
      return value;
    }

    const result = this.schema.safeParse(value);

    if (!result.success) {
      const message = result.error.issues[0]?.message || 'Validation error';
      throw new BadRequestException({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message,
        },
      });
    }

    return result.data;
  }
}
