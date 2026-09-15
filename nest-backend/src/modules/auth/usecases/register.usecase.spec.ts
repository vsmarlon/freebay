import { RegisterUseCase } from './register.usecase';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { EmailAlreadyExistsError, UsernameAlreadyExistsError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

describe('RegisterUseCase', () => {
  let sut: RegisterUseCase;
  let mockUserRepository: jest.Mocked<Partial<UserDatabaseRepository>>;

  beforeEach(async () => {
    mockUserRepository = {
      findByEmail: jest.fn().mockResolvedValue(right(null)),
      findByUsername: jest.fn().mockResolvedValue(right(null)),
      create: jest.fn().mockResolvedValue(right({
        id: 'user-123',
        displayName: 'John Doe',
        username: 'john_doe',
        email: 'john@example.com',
        passwordHash: 'hashedpassword',
        emailVerified: false,
        cpfHash: null,
        phone: null,
        phoneVerified: false,
        city: null,
        state: null,
        avatarUrl: null,
        bio: null,
        isVerified: false,
        isGuest: false,
        role: 'USER',
        reputationScore: 0,
        totalReviews: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      })),
    } as jest.Mocked<Partial<UserDatabaseRepository>>;

    sut = new RegisterUseCase(mockUserRepository as UserDatabaseRepository);
  });

  it('registers a new user', async () => {
    const input = {
      displayName: 'John Doe',
      username: 'john_doe',
      email: 'john@example.com',
      password: 'password123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.user.displayName).toBe('John Doe');
    }
  });

  it('returns error if email already exists', async () => {
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue(right({
      id: 'existing-user',
      email: 'john@example.com',
      passwordHash: 'hashedpassword',
      displayName: 'John Doe',
    }));

    const input = {
      displayName: 'John Doe',
      username: 'john_doe',
      email: 'john@example.com',
      password: 'password123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(EmailAlreadyExistsError);
    }
  });

  it('returns error if username already exists', async () => {
    mockUserRepository.findByUsername = jest.fn().mockResolvedValue(right({
      id: 'existing-user',
      email: 'someone-else@example.com',
      passwordHash: 'hashedpassword',
      displayName: 'Someone Else',
      username: 'john_doe',
    }));

    const input = {
      displayName: 'John Doe',
      username: 'john_doe',
      email: 'john@example.com',
      password: 'password123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(UsernameAlreadyExistsError);
    }
  });

  it('creates user with optional city and state', async () => {
    const input = {
      displayName: 'John Doe',
      username: 'john_doe',
      email: 'john@example.com',
      password: 'password123',
      city: 'São Paulo',
      state: 'SP',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockUserRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        city: 'São Paulo',
        state: 'SP',
      }),
    );
  });

  it('hashes password with bcrypt', async () => {
    const input = {
      displayName: 'John Doe',
      username: 'john_doe',
      email: 'john@example.com',
      password: 'password123',
    };

    await sut.execute(input);

    expect(mockUserRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        passwordHash: expect.any(String),
      }),
    );
  });
});
