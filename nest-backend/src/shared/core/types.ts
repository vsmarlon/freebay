export enum JwtTokenType {
  ACCESS = 'access',
  REFRESH = 'refresh',
  BIOMETRIC = 'biometric',
}

export interface JwtPayload {
  userId: string;
  email?: string;
  role: string;
  isGuest?: boolean;
  type?: JwtTokenType;
  jti?: string;
  iat?: number;
  exp?: number;
}

export interface AuthUser extends JwtPayload {}
