import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from './infra/prisma/prisma.service';
import { RedisService } from './infra/redis/redis.service';
import { JwtTokenValidatorService } from './auth/jwt-token-validator.service';
import { SessionRevokerService } from './auth/session-revoker.service';
import { RolesGuard } from './guards/roles.guard';
import { AppleProviderService } from './auth/apple-provider.service';

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
  providers: [
    PrismaService,
    RedisService,
    JwtTokenValidatorService,
    SessionRevokerService,
    AppleProviderService,
    RolesGuard,
  ],
  exports: [
    PrismaService,
    RedisService,
    JwtModule,
    JwtTokenValidatorService,
    SessionRevokerService,
    AppleProviderService,
    RolesGuard,
  ],
})
export class SharedModule {}
