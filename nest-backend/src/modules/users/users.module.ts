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
import { PrismaUserRepository } from '@/modules/auth/repositories/prisma-user.repository';
import { FollowRepository } from './repositories/follow.repository';
import { BlockRepository } from './repositories/block.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
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
    PrismaUserRepository,
    FollowRepository,
    BlockRepository,
    PrismaService,
  ],
  exports: [FollowRepository, BlockRepository],
})
export class UsersModule {}
