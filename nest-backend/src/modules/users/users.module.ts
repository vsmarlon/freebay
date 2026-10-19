import { Module } from '@nestjs/common';
import { UsersAccountController } from './users-account.controller';
import { UsersDiscoveryController } from './users-discovery.controller';
import { UsersSocialController } from './users-social.controller';
import {
  GetProfileUseCase,
  GetUserStatsUseCase,
  UpdateProfileUseCase,
  RequestProfileVerificationUseCase,
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
  ListFollowersUseCase,
  ListFollowingUseCase,
  GetFollowStatusUseCase,
  GetBlockStatusUseCase,
} from './usecases';
import { AuthModule } from '@/modules/auth/auth.module';
import { FollowDatabaseRepository } from './data/repositories/follow-database.repository';
import { BlockDatabaseRepository } from './data/repositories/block-database.repository';
import { OrderDatabaseRepository } from '@/modules/orders/data/repositories/order-database.repository';
import { PhoneVerificationDatabaseRepository } from './data/repositories/phone-verification-database.repository';
import { AccountLifecycleDatabaseRepository } from './data/repositories/account-lifecycle-database.repository';
import { SmsService } from './services/sms.service';
import { TwilioSmsService } from './services/twilio-sms.service';
import { FollowRepository } from './domain/repositories/follow.repository';
import { BlockRepository } from './domain/repositories/block.repository';
import { UserLookupRepository } from './domain/repositories/user-lookup.repository';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { ManageSafetyListUseCase } from './usecases/manage-safety-list.usecase';
import { SafetyListRepository } from './domain/repositories/safety-list.repository';
import { SafetyListDatabaseRepository } from './data/repositories/safety-list-database.repository';

@Module({
  imports: [AuthModule],
  // Registration order matters: static routes (me/*, search, suggestions)
  // must win over the dynamic :id routes in UsersSocialController.
  controllers: [
    UsersAccountController,
    UsersDiscoveryController,
    UsersSocialController,
  ],
  providers: [
    GetProfileUseCase,
    GetUserStatsUseCase,
    UpdateProfileUseCase,
    RequestProfileVerificationUseCase,
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
    ListFollowersUseCase,
    ListFollowingUseCase,
    GetFollowStatusUseCase,
    GetBlockStatusUseCase,
    ManageSafetyListUseCase,
    SafetyListDatabaseRepository,
    { provide: SafetyListRepository, useExisting: SafetyListDatabaseRepository },
    AccountLifecycleDatabaseRepository,
    FollowDatabaseRepository,
    BlockDatabaseRepository,
    OrderDatabaseRepository,
    PhoneVerificationDatabaseRepository,
    TwilioSmsService,
    { provide: SmsService, useExisting: TwilioSmsService },
    { provide: FollowRepository, useExisting: FollowDatabaseRepository },
    { provide: BlockRepository, useExisting: BlockDatabaseRepository },
    { provide: UserLookupRepository, useExisting: UserDatabaseRepository },
  ],
  exports: [FollowDatabaseRepository, BlockDatabaseRepository, AccountLifecycleDatabaseRepository],
})
export class UsersModule {}
