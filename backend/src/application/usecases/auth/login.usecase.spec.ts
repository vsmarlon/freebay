import { LoginUseCase } from './login.usecase';
import { IUserRepository } from '@/domain/repositories';
import { UserEntity } from '@/domain/entities';

// Mock bcrypt
jest.mock('bcryptjs', () => ({
  compare: jest.fn(),
}));

import bcrypt from 'bcryptjs';

const mockUserRepository: jest.Mocked<IUserRepository> = {
  findById: jest.fn(),
  findByEmail: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
};

describe('LoginUseCase', () => {
  let sut: LoginUseCase;

  beforeEach(() => {
    sut = new LoginUseCase(mockUserRepository);
    jest.clearAllMocks();
  });

  it('should return left(InvalidCredentialsError) if user not found', async () => {
    mockUserRepository.findByEmail.mockResolvedValue(null);

    const result = await sut.execute({ email: 'test@test.com', password: '12345678' });

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('INVALID_CREDENTIALS');
    }
  });

  it('should return left(InvalidCredentialsError) if password does not match', async () => {
    const mockUser: UserEntity = {
      id: '1',
      displayName: 'Test',
      email: 'test@test.com',
      emailVerified: false,
      passwordHash: 'hashed',
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
    };

    mockUserRepository.findByEmail.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(false);

    const result = await sut.execute({ email: 'test@test.com', password: 'wrong' });

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('INVALID_CREDENTIALS');
    }
  });

  it('should return right(userData) on successful login', async () => {
    const mockUser: UserEntity = {
      id: '1',
      displayName: 'Test User',
      email: 'test@test.com',
      emailVerified: true,
      passwordHash: 'hashed',
      cpfHash: null,
      phone: null,
      phoneVerified: false,
      city: 'São Paulo',
      state: 'SP',
      avatarUrl: null,
      bio: null,
      isVerified: false,
      isGuest: false,
      role: 'USER',
      reputationScore: 0,
      totalReviews: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockUserRepository.findByEmail.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    const result = await sut.execute({ email: 'test@test.com', password: '12345678' });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toEqual({
        userId: '1',
        email: 'test@test.com',
        displayName: 'Test User',
      });
    }
  });
});
