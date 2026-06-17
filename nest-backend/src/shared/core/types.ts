export interface JwtPayload {
  userId: string;
  email?: string;
  role: string;
  isGuest?: boolean;
  type?: 'access' | 'refresh';
  jti?: string;
  iat?: number;
  exp?: number;
}

export interface AuthUser extends JwtPayload {}
