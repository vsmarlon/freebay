import { GuestOutput } from './input/AuthInput';

export class GuestUseCase {
  async execute(): Promise<GuestOutput> {
    const guestNumber = Math.floor(Math.random() * 1000000)
      .toString()
      .padStart(6, '0');

    return {
      userId: `guest_${guestNumber}`,
      displayName: `Guest_${guestNumber}`,
    };
  }
}
