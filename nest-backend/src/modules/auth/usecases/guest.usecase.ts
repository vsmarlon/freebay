import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { GuestResponse } from '../mappers/auth.mapper';

@Injectable()
export class GuestUseCase {
  async execute(): Promise<Either<AppError, GuestResponse>> {
    const guestNumber = Math.floor(Math.random() * 1000000)
      .toString()
      .padStart(6, '0');

    const guestToken = Buffer.from(`guest_${guestNumber}`).toString('base64');

    return right({
      userId: `guest_${guestNumber}`,
      guestToken,
    });
  }
}
