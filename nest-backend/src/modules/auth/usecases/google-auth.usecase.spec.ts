import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { GoogleAuthUseCase } from './google-auth.usecase';
import { UserRepository } from '../domain/repositories/user.repository';
import { right } from '@/shared/core/either';

const mockVerifyIdToken = jest.fn();

jest.mock('google-auth-library', () => {
  return {
    OAuth2Client: jest.fn().mockImplementation(() => {
      return {
        verifyIdToken: mockVerifyIdToken,
      };
    }),
  };
});

describe('GoogleAuthUseCase', () => {
  let sut: GoogleAuthUseCase;
  let mockUserRepository: {
    findByGoogleId: jest.Mock;
    findByEmail: jest.Mock;
    update: jest.Mock;
    create: jest.Mock;
  };
  let mockConfigService: { get: jest.Mock };

  beforeEach(async () => {
    jest.clearAllMocks();

    mockUserRepository = {
      findByGoogleId: jest.fn().mockResolvedValue(right(null)),
      findByEmail: jest.fn().mockResolvedValue(right(null)),
      update: jest.fn(),
      create: jest.fn(),
    };

    mockConfigService = {
      get: jest.fn().mockImplementation((key: string) => {
        if (key === 'GOOGLE_CLIENT_ID') return 'mock-client-id.apps.googleusercontent.com';
        return null;
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GoogleAuthUseCase,
        { provide: UserRepository, useValue: mockUserRepository },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    sut = module.get<GoogleAuthUseCase>(GoogleAuthUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should authenticate an existing Google user by googleId', async () => {
    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-sub-123',
        email: 'test@gmail.com',
        name: 'Test User',
        picture: 'https://avatar.com/pic.png',
        email_verified: true,
      }),
    });

    const existingUser = {
      id: 'user-google-1',
      displayName: 'Existing User',
      username: 'existing_user',
      email: 'test@gmail.com',
      passwordHash: null,
      googleId: 'google-sub-123',
      emailVerified: true,
      cpfHash: null,
      phone: null,
      phoneVerified: false,
      city: 'São Paulo',
      state: 'SP',
      avatarUrl: 'https://avatar.com/pic.png',
      bio: null,
      isVerified: false,
      isGuest: false,
      role: 'USER',
      reputationScore: 0,
      totalReviews: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockUserRepository.findByGoogleId.mockResolvedValue(right(existingUser as any));

    const result = await sut.execute('valid-google-id-token');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.user.id).toBe('user-google-1');
      expect(result.value.user.username).toBe('existing_user');
    }
  });

  it('should link Google account when user exists with matching email', async () => {
    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-sub-456',
        email: 'email-user@gmail.com',
        name: 'Email User',
        picture: 'https://avatar.com/new.png',
        email_verified: true,
      }),
    });

    const existingEmailUser = {
      id: 'user-email-1',
      displayName: 'Email User',
      username: 'email_user',
      email: 'email-user@gmail.com',
      passwordHash: 'some-hash',
      googleId: null,
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
    };

    mockUserRepository.findByGoogleId.mockResolvedValue(right(null));
    mockUserRepository.findByEmail.mockResolvedValue(right(existingEmailUser as any));
    mockUserRepository.update.mockResolvedValue(right({
      ...existingEmailUser,
      googleId: 'google-sub-456',
      emailVerified: true,
      avatarUrl: 'https://avatar.com/new.png',
    } as any));

    const result = await sut.execute('valid-google-id-token');

    expect(result.isRight()).toBe(true);
    expect(mockUserRepository.update).toHaveBeenCalledWith('user-email-1', {
      googleId: 'google-sub-456',
      emailVerified: true,
      avatarUrl: 'https://avatar.com/new.png',
    });
  });

  it('should create a new user with username: null when user does not exist', async () => {
    mockVerifyIdToken.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-sub-789',
        email: 'newuser@gmail.com',
        name: 'New Google User',
        picture: 'https://avatar.com/pic.png',
        email_verified: true,
      }),
    });

    const newlyCreatedUser = {
      id: 'new-user-id',
      displayName: 'New Google User',
      username: null,
      email: 'newuser@gmail.com',
      passwordHash: null,
      googleId: 'google-sub-789',
      emailVerified: true,
      cpfHash: null,
      phone: null,
      phoneVerified: false,
      city: null,
      state: null,
      avatarUrl: 'https://avatar.com/pic.png',
      bio: null,
      isVerified: false,
      isGuest: false,
      role: 'USER',
      reputationScore: 0,
      totalReviews: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockUserRepository.findByGoogleId.mockResolvedValue(right(null));
    mockUserRepository.findByEmail.mockResolvedValue(right(null));
    mockUserRepository.create.mockResolvedValue(right(newlyCreatedUser as any));

    const result = await sut.execute('valid-google-id-token');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.user.id).toBe('new-user-id');
      expect(result.value.user.username).toBeNull();
    }
    expect(mockUserRepository.create).toHaveBeenCalledWith(expect.objectContaining({
      displayName: 'New Google User',
      username: null,
      email: 'newuser@gmail.com',
      googleId: 'google-sub-789',
    }));
  });

  it('should return error when Google token is invalid', async () => {
    mockVerifyIdToken.mockRejectedValue(new Error('Invalid token'));

    const result = await sut.execute('invalid-token');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value.code).toBe('INVALID_GOOGLE_TOKEN');
    }
  });
});
