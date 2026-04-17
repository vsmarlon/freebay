import { Test, TestingModule } from '@nestjs/testing';
import { RegisterUseCase } from './register.usecase';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { EmailAlreadyExistsError } from '@/shared/core/errors';

describe('RegisterUseCase', () => {
  let sut: RegisterUseCase;
  let mockUserRepository: any;

  beforeEach(async () => {
    mockUserRepository = {
      findByEmail: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockResolvedValue({
        id: 'user-123',
        displayName: 'John Doe',
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
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegisterUseCase,
        { provide: PrismaUserRepository, useValue: mockUserRepository },
      ],
    }).compile();

    sut = module.get<RegisterUseCase>(RegisterUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should register a new user', async () => {
    const input = {
      displayName: 'John Doe',
      email: 'john@example.com',
      password: 'password123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.user.displayName).toBe('John Doe');
    }
  });

  it('should return error if email already exists', async () => {
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue({
      id: 'existing-user',
      email: 'john@example.com',
      passwordHash: 'hashedpassword',
      displayName: 'John Doe',
    });

    const input = {
      displayName: 'John Doe',
      email: 'john@example.com',
      password: 'password123',
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(EmailAlreadyExistsError);
    }
  });

  it('should create user with optional city and state', async () => {
    const input = {
      displayName: 'John Doe',
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

  it('should hash password with bcrypt', async () => {
    const input = {
      displayName: 'John Doe',
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
