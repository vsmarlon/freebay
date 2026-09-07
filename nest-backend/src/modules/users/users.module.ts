import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import {
  GetProfileUseCase,
  GetUserStatsUseCase,
  UpdateProfileUseCase,
  UpdateFcmTokenUseCase,
  FollowUserUseCase,
  UnfollowUserUseCase,
  BlockUserUseCase,
  UnblockUserUseCase,
  SearchUsersUseCase,
  GetSuggestionsUseCase,
  RegisterPhoneUseCase,
  VerifyPhoneUseCase,
  RequestAccountDeletionUseCase,
  CancelAccountDeletionUseCase,
  ExportUserDataUseCase,
} from './usecases';
import { AuthModule } from '@/modules/auth/auth.module';
import { FollowRepository } from './domain/repositories/follow.repository';
import { PrismaFollowRepository } from './data/repositories/follow-database.repository';
import { BlockRepository } from './domain/repositories/block.repository';
import { PrismaBlockRepository } from './data/repositories/block-database.repository';
import { PrismaOrderRepository } from '@/modules/orders/data/repositories/order-database.repository';
import { PhoneVerificationRepository } from './domain/repositories/phone-verification.repository';
import { PhoneVerificationDatabaseRepository } from './data/repositories/phone-verification-database.repository';
import { AccountLifecycleRepository } from './domain/repositories/account-lifecycle.repository';
import { AccountLifecycleDatabaseRepository } from './data/repositories/account-lifecycle-database.repository';
import { SmsService } from './services/sms.service';
import { TwilioSmsService } from './services/twilio-sms.service';

@Module({
  imports: [AuthModule],
  controllers: [UsersController],
  providers: [
    GetProfileUseCase,
    GetUserStatsUseCase,
    UpdateProfileUseCase,
    UpdateFcmTokenUseCase,
    FollowUserUseCase,
    UnfollowUserUseCase,
    BlockUserUseCase,
    UnblockUserUseCase,
    SearchUsersUseCase,
    GetSuggestionsUseCase,
    RegisterPhoneUseCase,
    VerifyPhoneUseCase,
    RequestAccountDeletionUseCase,
    CancelAccountDeletionUseCase,
    ExportUserDataUseCase,
    AccountLifecycleDatabaseRepository,
    { provide: AccountLifecycleRepository, useExisting: AccountLifecycleDatabaseRepository },
    PrismaFollowRepository,
    { provide: FollowRepository, useExisting: PrismaFollowRepository },
    PrismaBlockRepository,
    { provide: BlockRepository, useExisting: PrismaBlockRepository },
    PrismaOrderRepository,
    PhoneVerificationDatabaseRepository,
    { provide: PhoneVerificationRepository, useExisting: PhoneVerificationDatabaseRepository },
    TwilioSmsService,
    { provide: SmsService, useExisting: TwilioSmsService },
  ],
  exports: [FollowRepository, BlockRepository, AccountLifecycleRepository],
})
export class UsersModule {}
