import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import {
  AppError,
  BadRequestError,
  ConflictError,
  UserNotFoundError,
} from '@/shared/core/errors';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { ModerationRepository } from '../domain/repositories/moderation.repository';

@Injectable()
export class SuspendUserUseCase {
  constructor(
    private readonly moderationRepository: ModerationRepository,
    private readonly sessionRevoker: SessionRevokerService,
  ) {}

  async execute(input: {
    targetUserId: string;
    adminId: string;
    suspend: boolean;
    reason?: string;
  }): Promise<Either<AppError, void>> {
    if (input.targetUserId === input.adminId) {
      return left(new BadRequestError('Você não pode suspender a própria conta'));
    }

    const existsResult = await this.moderationRepository.userExists(input.targetUserId);
    if (isLeft(existsResult)) return left(existsResult.value);
    if (!existsResult.value) return left(new UserNotFoundError());

    const suspensionResult = await this.moderationRepository.setUserSuspension(
      input.targetUserId,
      {
        suspendedAt: input.suspend ? new Date() : null,
        suspensionReason: input.suspend ? (input.reason ?? null) : null,
      },
    );
    if (isLeft(suspensionResult)) return left(suspensionResult.value);
    if (suspensionResult.value.count === 0) {
      return left(
        new ConflictError(
          input.suspend ? 'Usuário já está suspenso' : 'Usuário não está suspenso',
        ),
      );
    }

    if (input.suspend) {
      await this.sessionRevoker.revokeAllSessions(input.targetUserId);
    }

    const actionResult = await this.moderationRepository.recordAction({
      actorId: input.adminId,
      targetType: 'USER',
      targetId: input.targetUserId,
      action: input.suspend ? 'USER_SUSPENDED' : 'USER_UNSUSPENDED',
      reason: input.reason ?? null,
    });
    if (isLeft(actionResult)) return left(actionResult.value);

    return right(undefined);
  }
}
