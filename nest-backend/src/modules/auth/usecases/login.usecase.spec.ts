import { LoginUseCase } from './login.usecase';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { InvalidCredentialsError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import * as bcrypt from 'bcryptjs';

jest.mock('bcryptjs');

describe('LoginUseCase', () => {
  let sut: LoginUseCase;
  let mockUserRepository: jest.Mocked<Partial<UserDatabaseRepository>>;

  beforeEach(async () => {
    mockUserRepository = {
      findByEmail: jest.fn(),
    } as jest.Mocked<Partial<UserDatabaseRepository>>;

    sut = new LoginUseCase(mockUserRepository as UserDatabaseRepository);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should return error if user not found', async () => {
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue(right(null));

    const input = { email: 'notfound@example.com', password: 'password123' };
    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidCredentialsError);
    }
  });

  it('should return error if password does not match', async () => {
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue(right({
      id: 'user-123',
      email: 'john@example.com',
      passwordHash: '$2a$12$somehashedpasswordstring',
    }));

    (bcrypt.compare as jest.Mock).mockResolvedValue(false);

    const input = { email: 'john@example.com', password: 'wrongPassword' };
    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidCredentialsError);
    }
  });

  it('should return user data on successful login', async () => {
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue(right({
      id: 'user-123',
      email: 'john@example.com',
      displayName: 'John Doe',
      passwordHash: '$2a$12$somehashedpasswordstring',
    }));

    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    const input = { email: 'john@example.com', password: 'correctPassword' };
    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.user.id).toBe('user-123');
      expect(result.value.user.displayName).toBe('John Doe');
    }
  });
});
