import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { GuestUseCase } from './usecases/guest.usecase';
import { ForgotPasswordUseCase } from './usecases/forgot-password.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { PrismaUserRepository } from './repositories/prisma-user.repository';
import { JwtStrategy } from './guards/jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
  ],
  controllers: [AuthController],
  providers: [
    RegisterUseCase,
    LoginUseCase,
    GuestUseCase,
    ForgotPasswordUseCase,
    ResetPasswordUseCase,
    PrismaUserRepository,
    JwtStrategy,
    JwtAuthGuard,
  ],
  exports: [PrismaUserRepository, JwtAuthGuard],
})
export class AuthModule {}
