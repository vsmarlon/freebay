import { Module } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RegisterUseCase } from './register.usecase';
import { LoginUseCase } from './login.usecase';
import { GuestUseCase } from './guest.usecase';
import { RequestPasswordRecoveryUseCase } from './request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './reset-password.usecase';
import { CheckUsernameAvailabilityUseCase } from './check-username-availability.usecase';
import { UserRepository } from '../domain/repositories/user.repository';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { PasswordRecoveryRepository } from '../domain/repositories/password-recovery.repository';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResendService } from '../services/resend.service';

@Module({
  providers: [
    { provide: PrismaClient, useExisting: PrismaService },
    { provide: UserRepository, useClass: UserDatabaseRepository },
    { provide: PasswordRecoveryRepository, useClass: PasswordRecoveryDatabaseRepository },
    RegisterUseCase,
    LoginUseCase,
    GuestUseCase,
    RequestPasswordRecoveryUseCase,
    VerifyPasswordRecoveryCodeUseCase,
    ResetPasswordUseCase,
    CheckUsernameAvailabilityUseCase,
    ResendService,
  ],
  exports: [
    UserRepository,
    RegisterUseCase,
    LoginUseCase,
    GuestUseCase,
    RequestPasswordRecoveryUseCase,
    VerifyPasswordRecoveryCodeUseCase,
    ResetPasswordUseCase,
    CheckUsernameAvailabilityUseCase,
    ResendService,
  ],
})
export class AuthUseCasesModule {}
