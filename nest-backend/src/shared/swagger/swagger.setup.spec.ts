import { Module } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule } from '@nestjs/swagger';
import { setupSwagger } from './swagger.setup';

@Module({})
class EmptyAppModule {}

const originalNodeEnv = process.env.NODE_ENV;
const originalSwaggerEnabled = process.env.SWAGGER_ENABLED;
const originalTryItOut = process.env.SWAGGER_TRY_IT_OUT;

describe('Swagger setup', () => {
  afterEach(() => {
    if (originalSwaggerEnabled === undefined) delete process.env.SWAGGER_ENABLED;
    else process.env.SWAGGER_ENABLED = originalSwaggerEnabled;
    if (originalTryItOut === undefined) delete process.env.SWAGGER_TRY_IT_OUT;
    else process.env.SWAGGER_TRY_IT_OUT = originalTryItOut;
    if (originalNodeEnv === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = originalNodeEnv;
    jest.restoreAllMocks();
  });

  it('does not mount Swagger in production even when explicitly enabled', async () => {
    process.env.NODE_ENV = 'production';
    process.env.SWAGGER_ENABLED = 'true';
    const app = await NestFactory.create(EmptyAppModule, { logger: false });
    const mount = jest.spyOn(SwaggerModule, 'setup');
    try {
      expect(setupSwagger(app)).toBe(false);
      expect(mount).not.toHaveBeenCalled();
    } finally {
      await app.close();
    }
  });

  it('disables try-it-out and submit methods by default outside production', async () => {
    process.env.NODE_ENV = 'development';
    const app = await NestFactory.create(EmptyAppModule, { logger: false });
    const mount = jest.spyOn(SwaggerModule, 'setup');
    try {
      expect(setupSwagger(app)).toBe(true);
      expect(mount).toHaveBeenCalledWith('api', app, expect.any(Object), expect.objectContaining({
        swaggerOptions: expect.objectContaining({
          tryItOutEnabled: false,
          supportedSubmitMethods: [],
        }),
      }));
    } finally {
      await app.close();
    }
  });
});
