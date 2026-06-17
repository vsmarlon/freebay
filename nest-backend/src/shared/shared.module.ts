import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from './infra/prisma/prisma.service';
import { RedisService } from './infra/redis/redis.service';
import { EmailService } from './infra/email/email.service';
import { JwtTokenValidatorService } from './auth/jwt-token-validator.service';
import { RolesGuard } from './guards/roles.guard';
import { HealthController } from './http/health.controller';

@Global()
@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('JWT_SECRET'),
        signOptions: {
          expiresIn: config.get('JWT_EXPIRES_IN', '15m'),
        },
      }),
    }),
  ],
  controllers: [HealthController],
  providers: [PrismaService, RedisService, EmailService, JwtTokenValidatorService, RolesGuard],
  exports: [PrismaService, RedisService, EmailService, JwtModule, JwtTokenValidatorService, RolesGuard],
})
export class SharedModule {}
