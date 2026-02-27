export interface UserEntity {
  id: string;
  displayName: string;
  email: string;
  emailVerified: boolean;
  passwordHash: string;
  cpfHash: string | null;
  phone: string | null;
  phoneVerified: boolean;
  city: string | null;
  state: string | null;
  avatarUrl: string | null;
  bio: string | null;
  isVerified: boolean;
  isGuest: boolean;
  role: 'USER' | 'ADMIN' | 'GUEST';
  reputationScore: number;
  totalReviews: number;
  createdAt: Date;
  updatedAt: Date;
}

/** Public-safe user view — never exposes passwordHash, cpfHash, phone, email */
export type PublicUser = Pick<
  UserEntity,
  | 'id'
  | 'displayName'
  | 'avatarUrl'
  | 'bio'
  | 'city'
  | 'state'
  | 'isVerified'
  | 'reputationScore'
  | 'totalReviews'
  | 'createdAt'
>;
