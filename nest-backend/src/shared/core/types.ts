import { UserRole } from '@prisma/client';

export enum JwtTokenType {
  ACCESS = 'access',
  REFRESH = 'refresh',
  BIOMETRIC = 'biometric',
}

export interface JwtPayload {
  userId: string;
  email?: string;
  role: UserRole;
  type?: JwtTokenType;
  jti?: string;
  iat?: number;
  issuedAtMs?: number;
  authenticatedAtMs?: number;
  exp?: number;
}

export interface AuthUser extends JwtPayload {}
