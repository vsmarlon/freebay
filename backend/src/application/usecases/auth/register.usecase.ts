import { IUserRepository } from '@/domain/repositories';
import { Either, left, right } from '@/domain/either';
import { AppError, EmailAlreadyExistsError } from '@/domain/errors';
import bcrypt from 'bcryptjs';
import { RegisterInput, RegisterOutput } from './input/AuthInput';

export class RegisterUseCase {
  constructor(private userRepository: IUserRepository) {}

  async execute(input: RegisterInput): Promise<Either<AppError, RegisterOutput>> {
    const existingUser = await this.userRepository.findByEmail(input.email);
    if (existingUser) {
      return left(new EmailAlreadyExistsError());
    }

    const passwordHash = await bcrypt.hash(input.password, 12);

    const user = await this.userRepository.create({
      displayName: input.displayName,
      email: input.email,
      passwordHash,
      emailVerified: false,
      cpfHash: null,
      phone: null,
      phoneVerified: false,
      city: input.city ?? null,
      state: input.state ?? null,
      avatarUrl: null,
      bio: null,
      isVerified: false,
      isGuest: false,
      role: 'USER',
      reputationScore: 0,
      totalReviews: 0,
    });

    return right({
      user: {
        id: user.id,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        city: user.city,
        state: user.state,
        isVerified: user.isVerified,
        reputationScore: user.reputationScore,
        totalReviews: user.totalReviews,
        createdAt: user.createdAt,
      },
    });
  }
}
