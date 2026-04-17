import { Test, TestingModule } from '@nestjs/testing';
import { LoginUseCase } from './login.usecase';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { InvalidCredentialsError } from '@/shared/core/errors';
import * as bcrypt from 'bcryptjs';

jest.mock('bcryptjs');

describe('LoginUseCase', () => {
  let sut: LoginUseCase;
  let mockUserRepository: any;

  beforeEach(async () => {
    mockUserRepository = {
      findByEmail: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LoginUseCase,
        { provide: PrismaUserRepository, useValue: mockUserRepository },
      ],
    }).compile();

    sut = module.get<LoginUseCase>(LoginUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should return error if user not found', async () => {
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue(null);

    const input = { email: 'notfound@example.com', password: 'password123' };
    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidCredentialsError);
    }
  });

  it('should return error if password does not match', async () => {
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue({
      id: 'user-123',
      email: 'john@example.com',
      passwordHash: await bcrypt.hash('correctPassword', 12),
    });

    (bcrypt.compare as jest.Mock).mockResolvedValue(false);

    const input = { email: 'john@example.com', password: 'wrongPassword' };
    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidCredentialsError);
    }
  });

  it('should return user data on successful login', async () => {
    const hashedPassword = await bcrypt.hash('correctPassword', 12);
    mockUserRepository.findByEmail = jest.fn().mockResolvedValue({
      id: 'user-123',
      email: 'john@example.com',
      displayName: 'John Doe',
      passwordHash: hashedPassword,
    });

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
