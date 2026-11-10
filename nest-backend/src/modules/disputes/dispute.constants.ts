import { DisputeStatus } from '@prisma/client';

export const DISPUTE_OPENING_WINDOW_HOURS = 48;
export const DISPUTE_EXPIRY_WINDOW_HOURS = 72;
export const DISPUTE_HOUR_IN_MILLISECONDS = 60 * 60 * 1000;

export const ACTIVE_DISPUTE_STATUSES: DisputeStatus[] = [
  DisputeStatus.OPEN,
  DisputeStatus.AWAITING_SELLER,
  DisputeStatus.AWAITING_BUYER,
];

export enum DisputeWinner {
  BUYER = 'BUYER',
  SELLER = 'SELLER',
}

export const DISPUTE_AUTO_RESOLUTION = 'Auto-resolved: dispute window expired';
