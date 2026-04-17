import { Injectable } from '@nestjs/common';
import { GuestResponse } from '../mappers/auth.mapper';

@Injectable()
export class GuestUseCase {
  async execute(): Promise<GuestResponse> {
    const guestNumber = Math.floor(Math.random() * 1000000)
      .toString()
      .padStart(6, '0');

    const guestToken = Buffer.from(`guest_${guestNumber}`).toString('base64');

    return {
      userId: `guest_${guestNumber}`,
      guestToken,
    };
  }
}
