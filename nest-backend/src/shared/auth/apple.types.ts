export interface AppleIdentity {
  sub: string;
  email?: string;
  emailVerified?: boolean;
  nonce: string;
}
