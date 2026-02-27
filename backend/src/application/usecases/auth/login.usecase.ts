import { IUserRepository } from '@/domain/repositories';
import { Either, left, right } from '@/domain/either';
import { AppError, InvalidCredentialsError } from '@/domain/errors';
import bcrypt from 'bcryptjs';
import { LoginInput, LoginOutput } from './input/AuthInput';

export class LoginUseCase {
  constructor(private userRepository: IUserRepository) {}

  async execute(input: LoginInput): Promise<Either<AppError, LoginOutput>> {
    const user = await this.userRepository.findByEmail(input.email);
    if (!user) {
      return left(new InvalidCredentialsError());
    }

    const passwordMatch = await bcrypt.compare(input.password, user.passwordHash);
    if (!passwordMatch) {
      return left(new InvalidCredentialsError());
    }

    return right({
      userId: user.id,
      email: user.email,
      displayName: user.displayName,
    });
  }
}
