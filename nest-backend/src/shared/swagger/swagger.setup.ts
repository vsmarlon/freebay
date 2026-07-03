import { INestApplication } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

export function setupSwagger(app: INestApplication): void {
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
}
