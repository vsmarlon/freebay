import { User } from '@prisma/client';
import { toUserResponse, UserResponse } from '../../users/mappers/user.mapper';

export interface AuthResponse {
  user: UserResponse;
}

export interface LoginResponse {
  user: UserResponse;
}

export interface GuestResponse {
  userId: string;
  guestToken: string;
}

export const toAuthResponse = (user: User): AuthResponse => ({
  user: toUserResponse(user),
});

export const toLoginResponse = (user: User): LoginResponse => ({
  user: toUserResponse(user),
});
