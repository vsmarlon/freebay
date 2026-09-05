import { User } from '@prisma/client';
import { toUserResponse, UserResponse } from '../../users/mappers/user.mapper';

export interface AuthResponse {
  user: UserResponse;
}

export interface LoginResponse {
  user: UserResponse;
}

export const toAuthResponse = (user: User): AuthResponse => ({
  user: toUserResponse(user, undefined, true),
});

export const toLoginResponse = (user: User): LoginResponse => ({
  user: toUserResponse(user, undefined, true),
});
