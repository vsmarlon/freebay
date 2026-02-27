import { PublicUser } from '@/domain/entities';

export interface RegisterInput {
  displayName: string;
  email: string;
  password: string;
  city?: string;
  state?: string;
}

export interface RegisterOutput {
  user: PublicUser;
}

export interface LoginInput {
  email: string;
  password: string;
}

export interface LoginOutput {
  userId: string;
  email: string;
  displayName: string;
}

export interface GuestOutput {
  userId: string;
  displayName: string;
}
