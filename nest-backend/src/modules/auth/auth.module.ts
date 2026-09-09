import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthUseCasesModule } from './usecases/auth-usecases.module';
import { JwtStrategy } from './guards/jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { WebOriginGuard } from './guards/web-origin.guard';

@Module({
  imports: [
    AuthUseCasesModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, JwtAuthGuard, WebOriginGuard],
  exports: [JwtAuthGuard, AuthUseCasesModule, AuthService],
})
export class AuthModule {}
