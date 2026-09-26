import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthWebSessionController } from './auth-web-session.controller';
import { AuthUseCasesModule } from './usecases/auth-usecases.module';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Module({
  imports: [AuthUseCasesModule],
  controllers: [AuthController, AuthWebSessionController],
  providers: [JwtAuthGuard],
  exports: [JwtAuthGuard, AuthUseCasesModule],
})
export class AuthModule {}
