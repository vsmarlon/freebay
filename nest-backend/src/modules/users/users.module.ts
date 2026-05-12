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
} from './usecases/user.usecase';
import { AuthModule } from '@/modules/auth/auth.module';
import { FollowRepository } from './repositories/follow.repository';
import { BlockRepository } from './repositories/block.repository';
import { PrismaOrderRepository } from '@/modules/orders/repositories/order.repository';

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
    FollowRepository,
    BlockRepository,
    PrismaOrderRepository,
  ],
  exports: [FollowRepository, BlockRepository],
})
export class UsersModule {}
