import { Module } from '@nestjs/common';
import { AuthApiModule } from './api/auth.module';
import { AuthUseCasesModule } from './usecases/auth-usecases.module';
import { JwtStrategy } from './guards/jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Module({
  imports: [AuthUseCasesModule, AuthApiModule],
  providers: [JwtStrategy, JwtAuthGuard],
  exports: [JwtAuthGuard, AuthUseCasesModule],
})
export class AuthModule {}
