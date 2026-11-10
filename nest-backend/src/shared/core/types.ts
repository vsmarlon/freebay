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
  sid?: string;
  jti?: string;
  iat?: number;
  issuedAtMs?: number;
  sessionStartedAtMs?: number;
  authenticatedAtMs?: number;
  exp?: number;
}

export interface AuthUser extends JwtPayload {}
