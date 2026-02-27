import { RegisterUseCase } from './register.usecase';
import { IUserRepository } from '@/domain/repositories';
import { UserEntity } from '@/domain/entities';

jest.mock('bcryptjs', () => ({
  hash: jest.fn().mockResolvedValue('hashed_password'),
}));

const mockUserRepository: jest.Mocked<IUserRepository> = {
  findById: jest.fn(),
  findByEmail: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
};

describe('RegisterUseCase', () => {
  let sut: RegisterUseCase;

  beforeEach(() => {
    sut = new RegisterUseCase(mockUserRepository);
    jest.clearAllMocks();
  });

  it('should return left(EmailAlreadyExistsError) if email already exists', async () => {
    mockUserRepository.findByEmail.mockResolvedValue({
      id: '1',
      displayName: 'Existing',
      email: 'test@test.com',
    } as UserEntity);

    const result = await sut.execute({
      displayName: 'New User',
      email: 'test@test.com',
      password: '12345678',
    });

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('EMAIL_ALREADY_EXISTS');
    }
  });

  it('should return right(user) without passwordHash', async () => {
    mockUserRepository.findByEmail.mockResolvedValue(null);

    const createdUser: UserEntity = {
      id: '1',
      displayName: 'New User',
      email: 'new@test.com',
      emailVerified: false,
      passwordHash: 'hashed_password',
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

    mockUserRepository.create.mockResolvedValue(createdUser);

    const result = await sut.execute({
      displayName: 'New User',
      email: 'new@test.com',
      password: '12345678',
    });

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.user).not.toHaveProperty('passwordHash');
      expect(result.value.user).not.toHaveProperty('email');
      expect(result.value.user.displayName).toBe('New User');
    }
    expect(mockUserRepository.create).toHaveBeenCalledTimes(1);
  });
});
