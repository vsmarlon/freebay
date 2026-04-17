import { PrismaClient, User, UserRole } from '@prisma/client';
import { generateTestEmail, generateTestCpfHash, hashPassword } from '../utils/test-helpers';

export class UserFactory {
  constructor(private prisma: PrismaClient) {}

  /**
   * Create a test user with default or custom values
   */
  async create(overrides: Partial<User> = {}): Promise<User> {
    const passwordHash = await hashPassword(overrides.passwordHash || 'password123');

    return this.prisma.user.create({
      data: {
        displayName: overrides.displayName || 'Test User',
        email: overrides.email || generateTestEmail(),
        passwordHash,
        emailVerified: overrides.emailVerified ?? false,
        cpfHash: overrides.cpfHash || (overrides.cpfHash !== null ? generateTestCpfHash() : null),
        phone: overrides.phone || null,
        phoneVerified: overrides.phoneVerified ?? false,
        city: overrides.city || null,
        state: overrides.state || null,
        avatarUrl: overrides.avatarUrl || null,
        bio: overrides.bio || null,
        isVerified: overrides.isVerified ?? false,
        isGuest: overrides.isGuest ?? false,
        role: overrides.role || UserRole.USER,
        reputationScore: overrides.reputationScore ?? 0,
        totalReviews: overrides.totalReviews ?? 0,
      },
    });
  }

  /**
   * Create a user with a wallet
   */
  async createWithWallet(
    overrides: Partial<User> = {},
    walletData: { availableBalance?: number; pendingBalance?: number; totalEarned?: number } = {},
  ): Promise<User> {
    const user = await this.create(overrides);

    await this.prisma.wallet.create({
      data: {
        userId: user.id,
        availableBalance: walletData.availableBalance ?? 0,
        pendingBalance: walletData.pendingBalance ?? 0,
        totalEarned: walletData.totalEarned ?? 0,
      },
    });

    return user;
  }

  /**
   * Create a verified user (email verified, with CPF)
   */
  async createVerified(overrides: Partial<User> = {}): Promise<User> {
    return this.create({
      emailVerified: true,
      isVerified: true,
      cpfHash: generateTestCpfHash(),
      ...overrides,
    });
  }

  /**
   * Create an admin user
   */
  async createAdmin(overrides: Partial<User> = {}): Promise<User> {
    return this.create({
      role: UserRole.ADMIN,
      emailVerified: true,
      isVerified: true,
      ...overrides,
    });
  }

  /**
   * Create a guest user
   */
  async createGuest(overrides: Partial<User> = {}): Promise<User> {
    return this.create({
      isGuest: true,
      emailVerified: false,
      email: generateTestEmail('guest'),
      ...overrides,
    });
  }

  /**
   * Create multiple users at once
   */
  async createMany(count: number, overrides: Partial<User> = {}): Promise<User[]> {
    const users: User[] = [];
    for (let i = 0; i < count; i++) {
      users.push(await this.create({ ...overrides, displayName: `${overrides.displayName || 'Test User'} ${i + 1}` }));
    }
    return users;
  }
}
