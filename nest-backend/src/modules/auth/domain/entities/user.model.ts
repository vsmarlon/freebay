import { Entity } from '@/shared/core/entity';
import { EntityResponse, right } from '@/shared/core/either';

export interface UserProps {
  id?: string;
  displayName: string;
  email: string;
  passwordHash: string;
  emailVerified?: boolean;
  isGuest?: boolean;
  role?: string;
  avatarUrl?: string | null;
  bio?: string | null;
  city?: string | null;
  state?: string | null;
  phone?: string | null;
  phoneVerified?: boolean;
  cpfHash?: string | null;
  isVerified?: boolean;
  reputationScore?: number;
  totalReviews?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export class UserModel extends Entity {
  readonly id?: string;
  readonly displayName: string;
  readonly email: string;
  readonly passwordHash: string;
  readonly emailVerified: boolean;
  readonly isGuest: boolean;
  readonly role: string;
  readonly avatarUrl?: string | null;
  readonly bio?: string | null;
  readonly city?: string | null;
  readonly state?: string | null;
  readonly phone?: string | null;
  readonly phoneVerified: boolean;
  readonly cpfHash?: string | null;
  readonly isVerified: boolean;
  readonly reputationScore: number;
  readonly totalReviews: number;
  readonly createdAt?: Date;
  readonly updatedAt?: Date;

  private constructor(props: UserProps) {
    super(props as unknown as Record<string, unknown>);
    this.id = props.id;
    this.displayName = props.displayName;
    this.email = props.email;
    this.passwordHash = props.passwordHash;
    this.emailVerified = props.emailVerified ?? false;
    this.isGuest = props.isGuest ?? false;
    this.role = props.role ?? 'USER';
    this.avatarUrl = props.avatarUrl ?? null;
    this.bio = props.bio ?? null;
    this.city = props.city ?? null;
    this.state = props.state ?? null;
    this.phone = props.phone ?? null;
    this.phoneVerified = props.phoneVerified ?? false;
    this.cpfHash = props.cpfHash ?? null;
    this.isVerified = props.isVerified ?? false;
    this.reputationScore = props.reputationScore ?? 0;
    this.totalReviews = props.totalReviews ?? 0;
    this.createdAt = props.createdAt;
    this.updatedAt = props.updatedAt;
  }

  static create(props: UserProps): EntityResponse<UserModel> {
    return right(new UserModel(props));
  }
}
