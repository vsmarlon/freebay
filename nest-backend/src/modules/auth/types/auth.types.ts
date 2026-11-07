import { User } from '@prisma/client';

export type ConsumedMagicLink = { user: User; sessionStartedAtMs: number };
