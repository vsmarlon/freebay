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
import { PrismaFollowRepository } from './data/repositories/follow-database.repository';
import { PrismaBlockRepository } from './data/repositories/block-database.repository';
import { PrismaOrderRepository } from '@/modules/orders/data/repositories/order-database.repository';
import { PhoneVerificationDatabaseRepository } from './data/repositories/phone-verification-database.repository';
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
    AccountLifecycleDatabaseRepository,
    PrismaFollowRepository,
    PrismaBlockRepository,
    PrismaOrderRepository,
    PhoneVerificationDatabaseRepository,
    TwilioSmsService,
    { provide: SmsService, useExisting: TwilioSmsService },
  ],
  exports: [PrismaFollowRepository, PrismaBlockRepository, AccountLifecycleDatabaseRepository],
})
export class UsersModule {}
