import { PrismaClient, User, UserRole } from '@prisma/client';
import { generateTestEmail, generateTestCpfHash, generateTestUsername, hashPassword } from '../utils/test-helpers';

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
        username: overrides.username || generateTestUsername(),
        email: overrides.email || generateTestEmail(),
        passwordHash,
        emailVerified: overrides.emailVerified ?? false,
        cpfHash: overrides.cpfHash || (overrides.cpfHash !== null ? generateTestCpfHash() : null),
        cpf: overrides.cpf ?? null,
        phone: overrides.phone || null,
        phoneVerified: overrides.phoneVerified ?? false,
        city: overrides.city || null,
        state: overrides.state || null,
        avatarUrl: overrides.avatarUrl || null,
        bio: overrides.bio || null,
        isVerified: overrides.isVerified ?? false,
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

}
