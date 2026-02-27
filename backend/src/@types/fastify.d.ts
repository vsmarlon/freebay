export interface JwtSignPayload {
  userId?: string;
  isGuest?: boolean;
  role: 'USER' | 'ADMIN' | 'GUEST';
  type?: 'refresh';
  jti: string;
}

export interface JwtPayload extends JwtSignPayload {
  iat: number;
  exp: number;
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: JwtSignPayload;
    user: JwtPayload;
  }
}
