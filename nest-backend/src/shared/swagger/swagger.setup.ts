import { INestApplication } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

export function setupSwagger(app: INestApplication): boolean {
  if (process.env.NODE_ENV === 'production' || process.env.SWAGGER_ENABLED === 'false') return false;
  const config = new DocumentBuilder()
    .setTitle('FreeBay API')
    .setDescription(
      'FreeBay - C2C Hybrid Marketplace API\n\n' +
        '• Success responses: `{ "success": true, "data": <payload> }`\n' +
        '• Error responses: `{ "success": false, "error": { "code", "message" }, "timestamp", "path" }`',
    )
    .setVersion('1.0')
    .addServer(`http://localhost:${process.env.PORT || 3000}`, 'Local development')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter JWT Bearer token',
      },
      'bearer',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document, {
    swaggerOptions: {
      docExpansion: 'none',
      filter: true,
      persistAuthorization: true,
      tagsSorter: 'alpha',
      operationsSorter: 'alpha',
      tryItOutEnabled: process.env.SWAGGER_TRY_IT_OUT === 'true',
      supportedSubmitMethods: process.env.SWAGGER_TRY_IT_OUT === 'true'
        ? ['get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace']
        : [],
    },
    customSiteTitle: 'FreeBay API Docs',
  });
  return true;
}
